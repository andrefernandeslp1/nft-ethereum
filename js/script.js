// Inicialize o contrato
var contractAddress = '0x0fA1B00ED1f1d596A30E86B9A3Ea963BEFBdb9e6';

// Inicializa o objeto DApp
document.addEventListener("DOMContentLoaded", onDocumentLoad);
function onDocumentLoad() {
  DApp.init();
}

// Nosso objeto DApp que irá armazenar a instância web3
const DApp = {
  web3: null,
  contracts: {},
  account: null,

  init: function () {
    return DApp.initWeb3();
  },

  // Inicializa o provedor web3
  initWeb3: async function () {
    if (typeof window.ethereum !== "undefined") {
      try {
        const accounts = await window.ethereum.request({ // Requisita primeiro acesso ao Metamask
          method: "eth_requestAccounts",
        });
        DApp.account = accounts[0];
        window.ethereum.on('accountsChanged', DApp.updateAccount); // Atualiza se o usuário trcar de conta no Metamaslk
      } catch (error) {
        console.error("Usuário negou acesso ao web3!");
        return;
      }
      DApp.web3 = new Web3(window.ethereum);
    } else {
      console.error("Instalar MetaMask!");
      return;
    }
    return DApp.initContract();
  },

  // Atualiza 'DApp.account' para a conta ativa no Metamask
  updateAccount: async function() {
    DApp.account = (await DApp.web3.eth.getAccounts())[0];
    atualizaInterface();
  },

  // Associa ao endereço do seu contrato
  initContract: async function () {
    DApp.contracts.TituloCredito = new DApp.web3.eth.Contract(abi, contractAddress);
    return DApp.render();
  },

  // Inicializa a interface HTML com os dados obtidos
  render: async function () {
    inicializaInterface();
  },
};

// *** MÉTODOS DO CONTRATO ** //
/*
function getValorAtual () {
  let _id = document.getElementById("detalhar").value;
  return DApp.contracts.TituloCredito.methods.getValorAtual(_id).call({ from: DApp.account }).then((result) => {
    document.getElementById("output1").innerHTML = "Valor Atual: " + result + "<br>";
  });
}
*/
var currentValue;

function getValue (_id) {
  return new Promise((resolve, reject) => {
    DApp.contracts.TituloCredito.methods.getValorAtual(_id).call({ from: DApp.account }).then((result) => {
      currentValue = result;
      resolve();
    });
  });
} 

function emitirNovoTitulo () {
  let _valor = document.getElementById("valor").value;
  return DApp.contracts.TituloCredito.methods.emitirNovoTitulo(_valor).send({ from: DApp.account, value: _valor }).then(atualizaInterface);
}

function resgatarTitulo () {
  let _id = document.getElementById("resgatar").value;
  if (_id == 0) {
    sacarSaldo();
  }
  else {
    return DApp.contracts.TituloCredito.methods.resgatarTitulo(_id).send({ from: DApp.account }).then(atualizaInterface);
  }
}

function comprarTituloNegociavel () {
  let _id = document.getElementById("comprar").value;
  getValue(_id).then(() => {
    console.log(currentValue);
    return DApp.contracts.TituloCredito.methods.comprarTituloNegociavel(_id).send({ from: DApp.account, value: currentValue }).then(atualizaInterface);
  });
}

function setNegociavel () {
  let _id = document.getElementById("negociavel").value;
  return DApp.contracts.TituloCredito.methods.setNegociavel(_id).send({ from: DApp.account }).then(atualizaInterface);
}

function getTitulo () {
  //getValorAtual();
  let _id = document.getElementById("detalhar").value;
  getValue(_id).then(() => {
    console.log(currentValue);
    return DApp.contracts.TituloCredito.methods.getTitulo(_id).call({ from: DApp.account }).then((result) => {
      document.getElementById("output2").innerHTML = "<br><b>Detalhes do Título:</b><br>ID do Título: " + result[0] + "<br> Portador: " + result[1] + "<br> Valor Inicial: " + result[2] + " wei<br> Timestamp Aquisição: " + result[3] + "<br> Resgatado: " + result[4] + "<br> Negociável: " + result[5] + "<br> Valor Atual: " + currentValue + " wei";
    });
  }
  );
}

function sacarSaldo () {
  return DApp.contracts.TituloCredito.methods.sacarSaldo().send({ from: DApp.account }).then(atualizaInterface);
}

function getSaldo () {
  return DApp.contracts.TituloCredito.methods.getSaldo().call({ from: DApp.account });
}

function getIdTitulo () {
  return DApp.contracts.TituloCredito.methods.getIdTitulo().call({ from: DApp.account });
}

// *** ATUALIZAÇÃO DO HTML *** //

function inicializaInterface() {
  document.getElementById("btn-emitir").onclick = emitirNovoTitulo;
  document.getElementById("btn-resgatar").onclick = resgatarTitulo;
  document.getElementById("btn-comprar").onclick = comprarTituloNegociavel;
  document.getElementById("btn-negociavel").onclick = setNegociavel;
  //document.getElementById("btn-valoratual").onclick = getValorAtual;
  document.getElementById("btn-detalhar").onclick = getTitulo;
  //document.getElementById("btn-sacarSaldo").onclick = sacarSaldo;
  atualizaInterface();
  //DApp.contracts.TituloCredito.getPastEvents("TituloEmitido", { fromBlock: 0, toBlock: "latest" }).then((result) => registraEventos(result));
  //DApp.contracts.TituloCredito.events.TituloEmitido((error, event) => registraEventos([event]));
}

function atualizaInterface() {
  getSaldo().then((result) => {
    document.getElementById("output0").innerHTML = result + " wei";
  });
  getIdTitulo().then((result) => {
    document.getElementById("titulosEmitidos").innerHTML = result;
  });
  DApp.contracts.TituloCredito.getPastEvents("TituloEmitido", { fromBlock: 0, toBlock: "latest" }).then((result) => registraEventos(result));
  //DApp.contracts.TituloCredito.events.TituloEmitido((error, event) => registraEventos([event]));
}

function registraEventos(eventos){
  let lista = document.getElementById("eventos");
  lista.innerHTML = "";
  eventos.forEach(evento => {
    let linha = document.createElement("li");
    linha.innerHTML = 
      "<b style='color:red'>" +evento.returnValues._operacao + "</b>" +
      " - ID: " + evento.returnValues._id + 
      " - Valor: " + evento.returnValues._valor + " wei" +
      " - Taxa: " + evento.returnValues._taxa + " wei" +
      " - Resgatado: " + evento.returnValues._pago +
      " - Negociável: " + evento.returnValues._negociavel +
      " - Transação: " + "<a href='https://sepolia.etherscan.io/tx/"+ evento.transactionHash +"'>" + evento.transactionHash + "</a>";
    lista.appendChild(linha);
  });
}


























