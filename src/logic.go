package main


import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)


//Chaincode
type KnowledgerChaincode struct {

}

func (chaincode *KnowledgerChaincode) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}


func(chaincode *KnowledgerChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	
}


// main function starts up the chaincode in the container during instantiate
func main() {
    if err := shim.Start(new(SimpleAsset)); err != nil {
            fmt.Printf("Error starting SimpleAsset chaincode: %s", err)
    }
}