import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React from "react";
import { Link } from "react-router-dom";       


function Gallery({readContracts}) {
    
    //const [Quantum, setQuantum] = useState()
    console.log("readcontracts", readContracts);
    const image = readContracts.Quanta.renderTokenById(1);

    return (
        <div>
            <svg height="210" width="500">
            {image}
            </svg>
        </div>
    );
}

export default Gallery;