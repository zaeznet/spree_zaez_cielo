#= require_self
class window.CieloCredit
  afterConstructor: ->

  beforeConstructor: ->

  constructor: (@credit_info, defaultExecution = true) ->
    do @beforeConstructor
    do @defaultExecution if defaultExecution
    do @afterConstructor

  defaultExecution: ->
    do @setRoutes
    do @setListeners
    do @setExistingOrNewCard

  getCreditInfo: ->
    @credit_info

  # Faz uma requisicao para pegar as parcelas disponiveis
  # para o tipo de bandeira digitada
  setCreditCard: ->
    $('#cielo_unrecognized').hide()
    type = $.payment.cardType($('#cielo_card_number').val())
    $('#cielo_credit_cc_type').val(type)
    if $('#cielo_card_number').val().length > 12
      if type == null
        $('#cielo_unrecognized').show()
        $('#cielo_portion').html('')
      else
        type = 'master' if type == 'mastercard'
        type = 'diners' if type == 'dinersclub'
        params =
          cc_type: type
        $.ajax
          url: Spree.routes.portions(Spree.current_order_id)
          data: params
          dataType: 'html'
          success: (ret) ->
            $('#cielo_portion').html(ret)
            $('input[type="radio"][name="portions"]').click => setPortionsValue('')
          error: (xhr) ->
            $('#cielo_portion').html(xhr.responseText)

  # Esconde as parcelas quando a opcao de cartao existente nao esta habilitada
  setExistingOrNewCard: ->
    if ($ '#existing_cards').is('*')
      ($ '#use_existing_card_yes').click ->
        ($ '#portions_existing_cards').show()
        # verifica se alguma parcela dos cartoes existentes esta checada
        # se sim, seta ela no input onde o valor e armazenado
        checked_portion = $("input[type='radio'][name='existing_card_portions']:checked").val()
        if parseInt(checked_portion) > 0
          $('#payment_portions').val(checked_portion)
        else
          $('#payment_portions').val('1')
      ($ '#use_existing_card_no').click ->
        ($ '#portions_existing_cards').hide()
        # o mesmo para os cartoes novos
        checked_portion = $("input[type='radio'][name='portions']:checked").val()
        if parseInt(checked_portion) > 0
          $('#payment_portions').val(checked_portion)
        else
          $('#payment_portions').val('1')

  # Faz uma requisicao para pegar as parcelas disponiveis
  # para o cartao existente
  setPortionsCard: ->
    card_checked = $('input[type=radio][name="order[existing_card]"]:checked').val()
    cielo_cards = JSON.parse($('#has_cielo_credit').val())
    if $.inArray(parseInt(card_checked), cielo_cards) >= 0
      params =
        credit_card_id: card_checked
        prefix: 'existing_card_'
      $.ajax
        url: Spree.routes.portions(Spree.current_order_id)
        data: params
        dataType: 'html'
        success: (response) ->
          $('#portions_existing_cards').html(response)
          $('input[type="radio"][name="existing_card_portions"]').click => setPortionsValue('existing_card_')
        error: (xhr) ->
          $('#portions_existing_cards').html(xhr.responseText)

  # Insere o valor da parcela selecionada
  setPortionsValue = (prefix) ->
    checked_portion = $("input[type='radio'][name='#{prefix}portions']:checked").val()
    $('#payment_portions').val(checked_portion)

  # Seta  os listeners do formulario
  setListeners: ->
    $('#cielo_card_number').on 'input', @setCreditCard
    $('div[data-hook="checkout_payment_step"] input[type="radio"]').click => do @verifySaveButtonVisibility
    $('input[type=radio][name="order[existing_card]"]').click => do @setPortionsCard

  # Insere a rota das parcelas no objeto que guarda as rotas
  setRoutes: ->
    Spree.routes.portions = (order_id) ->
      Spree.pathFor("api/orders/#{order_id}/portions")

  # Verifica a mudanca da escolha do tipo de pagamento
  # Se a escolhida nao for a CieloCredit retorna para 1 parcela
  verifySaveButtonVisibility: ->
    info = do @getCreditInfo
    checkedMethod = $('div[data-hook="checkout_payment_step"] input[type="radio"][name="order[payments_attributes][][payment_method_id]"]:checked')
    unless info.payment_method_id and info.payment_method_id.toString() == checkedMethod.val()
      $('#payment_portions').val('1')