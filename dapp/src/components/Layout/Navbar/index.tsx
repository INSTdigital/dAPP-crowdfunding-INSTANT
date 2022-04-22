import React from 'react';
import { logout, useGetAccountInfo } from '@elrondnetwork/dapp-core';
import { faSignOutAlt } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Navbar as BsNavbar, NavItem, Nav } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { dAppTitle } from 'config';
import { routeNames } from 'routes';
import { ReactComponent as ElrondLogo } from './../../../assets/img/elrond.svg';
import { ReactComponent as InstantLogo } from './../../../assets/img/instant.svg';

const Navbar = () => {
  const { address } = useGetAccountInfo();

  const handleLogout = () => {
    logout(`${window.location.origin}/unlock`);
  };

  const isLoggedIn = Boolean(address);

  return (
    <BsNavbar className='bg-white border-bottom px-4 py-3'>
      <div className='container-fluid'>
        <Link
          className='d-flex align-items-center navbar-brand mr-0'
          to={isLoggedIn ? routeNames.dashboard : routeNames.home}
        >
          <ElrondLogo className='elrond-logo' />
          <InstantLogo className='elrond-logo' />
          <span className='dapp-name text-muted'>{dAppTitle}</span>
        </Link>

        <Nav className='ml-auto'>
          {isLoggedIn && (
            <NavItem>
              <button className='btn btn-link' onClick={handleLogout}>
                <FontAwesomeIcon icon={faSignOutAlt} className='text-primary' />
              </button>
            </NavItem>
          )}
        </Nav>
      </div>
    </BsNavbar>
  );
};

export default Navbar;
