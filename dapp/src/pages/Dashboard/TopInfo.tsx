import * as React from 'react';
import { useGetAccountInfo, DappUI } from '@elrondnetwork/dapp-core';
import { contractAddress } from 'config';
import { dAppName } from 'config';

const TopInfo = () => {
  const { account } = useGetAccountInfo();

  return (
    <div className='text-white' data-testid='topInfo'>
      <h2 className='mb-1'>
        <span className='opacity-6 mr-1'>{dAppName}</span>
      </h2>
      <div className='mb-4'>
        <span className='opacity-6 mr-1'>Contract address:</span>
        <span data-testid='contractAddress'> {contractAddress}</span>
      </div>
      <div>
        <h4 className='py-2'>
          My balance{' '}
          <DappUI.Denominate value={account.balance} data-testid='balance' />
        </h4>
      </div>
    </div>
  );
};

export default TopInfo;
