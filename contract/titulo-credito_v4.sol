// Conta do contrato: 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TituloCredito {
  address public owner;
  uint256 public idTitulo = 0;
  uint256 public JUROS = 1; // 1% ao mês
  uint256 public TAXA_DE_EMISSAO = 2; // 2% do valor do título
  uint256 public TAXA_DE_TRANSFERENCIA = 1; // 1% do valor do título
  uint256 public saldo = 0;

  struct Titulo {
    uint256 id;
    address portador;
    uint256 valorInicial;
    uint256 time;
    bool pago;
    bool negociavel;
  }

  mapping(uint256 => Titulo) public titulosPorID;
  mapping(uint256 => address) public enderecoPorID;

  event TituloEmitido(uint256 _id, address _portador, uint256 _valor, uint256 _time, bool _pago, bool _negociavel);

  constructor() {
    owner = msg.sender;
  }

  function emitirNovoTitulo(uint256 _valor) public payable {
    uint256 valorTaxado = _valor - (_valor * TAXA_DE_EMISSAO / 100);
    require(msg.value == _valor, "Valor incorreto");
    require(_valor >= 100, "Valor minimo de 100");
    idTitulo++;
    titulosPorID[idTitulo] = Titulo(idTitulo, msg.sender, valorTaxado, block.timestamp, false, false);
    enderecoPorID[idTitulo] = msg.sender;
    saldo += _valor;
    emit TituloEmitido(idTitulo, msg.sender, valorTaxado, block.timestamp, false, false);
  }

  function setNegociavel (uint256 _id) public {
    require(msg.sender == enderecoPorID[_id], "Somente o portador pode negociar o titulo");
    require(titulosPorID[_id].pago == false, "Titulo ja resgatado");
    if (titulosPorID[_id].negociavel == false) {
      titulosPorID[_id].negociavel = true;
    }
    else {
      titulosPorID[_id].negociavel = false;
    }
    emit TituloEmitido(_id, msg.sender, getValorAtual(_id), block.timestamp, false, titulosPorID[_id].negociavel);
  }

  function comprarTituloNegociavel (uint256 _id) public payable {
    uint256 valorAtual = getValorAtual(_id);
    require(msg.value == valorAtual, "Valor incorreto");
    require(titulosPorID[_id].negociavel == true, "Titulo nao negociavel");
    require(titulosPorID[_id].pago == false, "Titulo ja resgatado");
    uint256 txTransferencia = valorAtual * TAXA_DE_TRANSFERENCIA / 100;
    uint256 valorLiquido = valorAtual - txTransferencia;
    payable(enderecoPorID[_id]).transfer(valorLiquido);
    titulosPorID[_id] = Titulo(_id, msg.sender, valorLiquido, block.timestamp, false, false);
    enderecoPorID[_id] = msg.sender;
    saldo += txTransferencia;
    emit TituloEmitido(_id, msg.sender, valorLiquido, block.timestamp, false, false);
  }

  function resgatarTitulo(uint256 _id) public payable {
    require(msg.sender == enderecoPorID[_id], "Somente o portador pode resgatar o titulo");
    require(titulosPorID[_id].pago == false, "Titulo ja resgatado");
    uint256 meses = (block.timestamp - titulosPorID[_id].time) / 30 days;
    uint256 valorJuros = (titulosPorID[_id].valorInicial * JUROS / 100) * meses;
    payable(msg.sender).transfer(titulosPorID[_id].valorInicial + valorJuros);
    titulosPorID[_id].pago = true;
    titulosPorID[_id].negociavel = false;
    saldo -= (titulosPorID[_id].valorInicial + valorJuros);
    emit TituloEmitido(_id, msg.sender, titulosPorID[_id].valorInicial + valorJuros, block.timestamp, true, false);
  } 

  function getValorAtual(uint256 _id) public view returns (uint256) {
    uint256 meses = (block.timestamp - titulosPorID[_id].time) / 30 days;
    uint256 valorJuros = (titulosPorID[_id].valorInicial * JUROS / 100) * meses;
    return titulosPorID[_id].valorInicial + valorJuros;
  }

  function getTitulo(uint256 _id) public view returns (Titulo memory) {
    return titulosPorID[_id];
  }

  function getSaldo() public view returns (uint256) {
    return saldo;
  }

  function getIdTitulo() public view returns (uint256) {
    return idTitulo;
  }

}
