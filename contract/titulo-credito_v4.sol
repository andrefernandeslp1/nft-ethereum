// Conta do contrato: 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TituloCredito {
  address public owner;
  uint256 public idTitulo = 0;
  uint256 public JUROS = 1; // 1% ao mês
  uint256 public TAXA_DE_EMISSAO = 2; // 2% do valor do título
  uint256 public TAXA_DE_TRANSFERENCIA = 1; // 1% do valor do título
  uint256 public TAXA_DE_RESGATE = 1; // 1% do valor do título
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

  event TituloEmitido(string _operacao, uint256 _id, address _portador, uint256 _valor, uint256 _time, bool _pago, bool _negociavel, uint256 _taxa);

  constructor() {
    owner = msg.sender;
  }

  function emitirNovoTitulo(uint256 _valor) external payable {
    uint256 valorTaxado = _valor - ((_valor * TAXA_DE_EMISSAO) / 100);
    require(msg.value == _valor, "Valor incorreto");
    require(_valor >= 10, "Valor minimo de 100");
    idTitulo++;
    titulosPorID[idTitulo] = Titulo(idTitulo, msg.sender, valorTaxado, block.timestamp, false, false);
    enderecoPorID[idTitulo] = msg.sender;
    saldo += _valor;
    emit TituloEmitido("E", idTitulo, msg.sender, valorTaxado, block.timestamp, false, false, (_valor * TAXA_DE_EMISSAO) / 100);
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
    emit TituloEmitido("N", _id, msg.sender, getValorAtual(_id), block.timestamp, false, titulosPorID[_id].negociavel, 0);
  }

  function comprarTituloNegociavel (uint256 _id) public payable {
    uint256 valorAtual = getValorAtual(_id);
    require(msg.value == valorAtual, "Valor incorreto");
    require(titulosPorID[_id].negociavel == true, "Titulo nao negociavel");
    require(titulosPorID[_id].pago == false, "Titulo ja resgatado");
    uint256 txTransferencia = (valorAtual * TAXA_DE_TRANSFERENCIA) / 100;
    uint256 valorLiquido = valorAtual - txTransferencia;
    payable(enderecoPorID[_id]).transfer(valorLiquido);
    titulosPorID[_id] = Titulo(_id, msg.sender, valorLiquido, block.timestamp, false, false);
    enderecoPorID[_id] = msg.sender;
    saldo += txTransferencia;
    emit TituloEmitido("C", _id, msg.sender, valorLiquido, block.timestamp, false, false, txTransferencia);
  }

  function resgatarTitulo(uint256 _id) public payable {
    require(msg.sender == enderecoPorID[_id], "Somente o portador pode resgatar o titulo");
    require(titulosPorID[_id].pago == false, "Titulo ja resgatado");
    uint256 meses = (block.timestamp - titulosPorID[_id].time) / 30 days;
    uint256 valorJuros = ((titulosPorID[_id].valorInicial * JUROS) / 100) * meses;
    uint256 valorAtual = titulosPorID[_id].valorInicial + valorJuros;
    uint256 txResgate = (valorAtual * TAXA_DE_RESGATE) / 100;
    uint256 valorLiquido = valorAtual - txResgate;
    payable(msg.sender).transfer(valorLiquido);
    titulosPorID[_id].pago = true;
    titulosPorID[_id].negociavel = false;
    saldo -= (valorLiquido);
    emit TituloEmitido("R", _id, msg.sender, valorLiquido, block.timestamp, true, false, txResgate);
  } 

  function sacarSaldo() public payable {
    require(msg.sender == owner, "Somente o dono do contrato pode resetar");
    saldo = 0;
    //transferir saldo para owner
    payable(owner).transfer(address(this).balance);
    emit TituloEmitido("X", 0, msg.sender, 0, block.timestamp, false, false, 0);
  }

  function getValorAtual(uint256 _id) public view returns (uint256) {
    uint256 meses = (block.timestamp - titulosPorID[_id].time) / 30 days;
    uint256 valorJuros = ((titulosPorID[_id].valorInicial * JUROS) / 100) * meses;
    return titulosPorID[_id].valorInicial + valorJuros;
  }

  function getTitulo(uint256 _id) public view returns (Titulo memory) {
    return titulosPorID[_id];
  }
/*
  function getSaldo() public view returns (uint256) {
    return saldo;
  }
*/
  function getSaldo() public view returns (uint256) {
    return address(this).balance;
  }

  function getIdTitulo() public view returns (uint256) {
    return idTitulo;
  }

}
