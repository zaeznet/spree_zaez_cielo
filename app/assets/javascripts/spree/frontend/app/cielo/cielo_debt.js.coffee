#= require_self
class window.CieloDebt
  afterConstructor: ->

  beforeConstructor: ->

  constructor: (@debt_info, defaultExecution = true) ->
    do @beforeConstructor
    do @defaultExecution if defaultExecution
    do @afterConstructor

  defaultExecution: ->
    $('#cielo_debt_number').on 'input', @setCreditCard
    $('#cielo_debt_authorize').click (e) => @authorizePayment(e)
    $('div[data-hook="checkout_payment_step"] input[type="radio"]').click => do @verifySaveButtonVisibility

  # Antes de fazer a requisicao a Cielo
  # verifica se o usuario inseriu um codigo de desconto
  # se sim, aplica ele ao pedido e faz a requisicao
  # se nao, exibe uma mensagem de erro e nao faz a requisicao
  authorizePayment: (e) ->
    e.preventDefault()
    $(e.target).attr('disabled', true).removeClass('primary').addClass 'disabled'
    info = do @getDebtInfo
    # aplica o cupom de desconto se existir
    coupon_code_field = $('#order_coupon_code')
    coupon_code = $.trim(coupon_code_field.val())
    if (coupon_code != '')
      if $('#coupon_status').length == 0
        coupon_status = $("<div id='coupon_status'></div>")
        coupon_code_field.parent().append(coupon_status)
      else
        coupon_status = $("#coupon_status")

      url = Spree.url(Spree.routes.apply_coupon_code(Spree.current_order_id),
        {
          order_token: Spree.current_order_token,
          coupon_code: coupon_code
        }
      )

      coupon_status.removeClass()

      $.ajax({
        async: false,
        method: "PUT",
        url: url,
        success: (data) ->
          coupon_code_field.val('')
          coupon_status.addClass("alert-success").html("Coupon code applied successfully.")
          makeRequestToCieloDebt(info)
        error: (xhr) ->
          handler = JSON.parse(xhr.responseText)
          coupon_status.addClass("alert-error").html(handler["error"])
          $('.continue').attr('disabled', false)
          $(e.target).attr('disabled', false).addClass('primary').removeClass 'disabled'
          return false
      })

    else
      makeRequestToCieloDebt(info)

  # Faz uma requisicao enviando as informacoes do cartao
  # se ocorrer tudo bem, redireciona para a pagina do banco para a autenticacao
  # se nao, exibe a mensagem de erro
  makeRequestToCieloDebt = (info) ->
    # verifica o tipo de cartao
    cc_type = $('#cielo_debt_cc_type').val()
    cc_type = 'master' if cc_type == 'mastercard' or cc_type == 'maestro'
    cc_type = 'visa' if cc_type == 'visaelectron'
    params =
      guest_token: Spree.current_order_token
      payment_method_id: info.payment_method_id
      source:
        number: $('#cielo_debt_number').val()
        name: $('#cielo_debt_name').val()
        cc_type: cc_type
        expiry: $('#cielo_debt_expiry').val()
        verification_value: $('#cielo_debt_code').val()
    $.ajax
      method: 'post'
      url: '/cielo_debt/create'
      data: params
      success: (json) ->
        window.location.replace json.url_auth
        $('#cielo_debt_authorize').attr('disabled', false).addClass('primary').removeClass 'disabled'
      error: (xhr) ->
        if xhr.responseJSON == undefined
          $('#cielo_debt_message').html(xhr.responseText)
        else
          $('#errorExplanationCielo').html(xhr.responseJSON.error)
          $('#errorExplanationCielo').fadeIn()
        $('#cielo_debt_authorize').attr('disabled', false).addClass('primary').removeClass 'disabled'

  # Retorna o objeto que guarda as informacoes do pagamento
  # (tipo de pagamento e total do pedido)
  getDebtInfo: ->
    @debt_info

  # Verifica se o cartao que esta sendo digitado esta disponivel
  # para a loja
  setCreditCard: ->
    $('#cielo_unrecognized').hide()
    type = $.payment.cardType($('#cielo_debt_number').val())
    type = 'master' if type == 'mastercard'
    if type == null
      $('#cielo_debt_unrecognized').show()
    else
      $('#cielo_debt_message').html("<img src='/assets/credit_cards/icons/#{type}.png' class='pull-right' />")
      $('#cielo_debt_unrecognized').hide()
      $('#cielo_debt_cc_type').val(type)

  # Verifica se deve esconder/exibir o botao de confirmacao do pagamento
  # Para debito, o pagamento e criado apenas apos a autenticacao,
  # por isso, e necessario outro botao (e rota)
  verifySaveButtonVisibility: ->
    info = do @getDebtInfo
    checkedMethod = $('div[data-hook="checkout_payment_step"] input[type="radio"][name="order[payments_attributes][][payment_method_id]"]:checked')
    if info.payment_method_id and info.payment_method_id.toString() == checkedMethod.val()
      $("#checkout_form_payment [data-hook=buttons]").hide()
    else
      $('#errorExplanationCielo').hide()
      $("#checkout_form_payment [data-hook=buttons]").show()