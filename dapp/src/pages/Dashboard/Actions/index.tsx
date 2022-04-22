import * as React from 'react';
import {
  useGetAccountInfo,
  transactionServices,
  refreshAccount
} from '@elrondnetwork/dapp-core';
import { Button } from 'react-bootstrap';
import { contractAddress, contractOwnerAddress } from 'config';

const Actions = () => {
  const [fund, setFund] = React.useState<number>(0);
  const /*transactionSessionId*/ [, setTransactionSessionId] = React.useState<
      string | null
    >(null);

  const { address } = useGetAccountInfo();
  const { sendTransactions } = transactionServices;

  const sendFundsTransaction = async () => {
    const pingTransaction = {
      value: fund * 10 ** 18,
      data: 'fund',
      receiver: contractAddress
    };
    await refreshAccount();

    const { sessionId /*, error*/ } = await sendTransactions({
      transactions: pingTransaction,
      transactionsDisplayInfo: {
        processingMessage: 'Sending funds',
        errorMessage: 'An error has occured when sending funds',
        successMessage: 'Send funds successfully'
      },
      redirectAfterSign: false
    });
    if (sessionId != null) {
      setTransactionSessionId(sessionId);
    }
  };

  const claimFundsTransaction = async () => {
    const claimTransaction = {
      value: '0',
      data: 'claim',
      receiver: contractAddress
    };
    await refreshAccount();

    const { sessionId /*, error*/ } = await sendTransactions({
      transactions: claimTransaction,
      transactionsDisplayInfo: {
        processingMessage: 'Claiming funds',
        errorMessage: 'An error has occured when claiming funds',
        successMessage: 'Claim funds successfully'
      },
      redirectAfterSign: false
    });
    if (sessionId != null) {
      setTransactionSessionId(sessionId);
    }
  };

  return (
    <div>
      <input type='number' onChange={(e) => setFund(e.target.valueAsNumber)} />{' '}
      <Button variant='dark' onClick={sendFundsTransaction}>
        Send
      </Button>{' '}
      {address == contractOwnerAddress && (
        <Button variant='dark' onClick={claimFundsTransaction}>
          Claim
        </Button>
      )}
    </div>
  );
};

export default Actions;
