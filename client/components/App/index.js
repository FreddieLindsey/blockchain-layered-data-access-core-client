import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'

import {
  BrowserRouter,
  Route
} from 'react-router-dom'

import Authenticate from '../Authenticate'

import FileViewer from '../FileViewer'
import FileMetadataList from '../FileMetadataList'
import FileDropper from '../FileDropper'
import SecureKeyLoader from '../SecureKeyLoader'

import {
  ipfsStorageAddressGet,
  ipfsStorageSizeGet,
  ipfsStorageIndexGet,
  fileRetrieve,
} from '../../actions'

const mapStateToProps = (state) => {
  return {
    accounts: state.accounts,
    files: state.files.stored,
    IPFSStorage: state.IPFSStorage
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    handleAddressGet: () => dispatch(ipfsStorageAddressGet()),
    handleSizeGet: () => dispatch(ipfsStorageSizeGet()),
    handleIndexGet: (i) => dispatch(ipfsStorageIndexGet(i)),
    handleFileRetrieve: (path) => dispatch(fileRetrieve(path)),
  }
}

class App extends Component {

  static displayName = 'App'
  static propTypes = {
    accounts: PropTypes.shape({
      all: PropTypes.arrayOf(PropTypes.string),
      default: PropTypes.string
    }).isRequired,
    files: PropTypes.object.isRequired,
    IPFSStorage: PropTypes.shape({
      address: PropTypes.string,
      size: PropTypes.number
    }).isRequired,

    handleAddressGet: PropTypes.func.isRequired,
    handleSizeGet: PropTypes.func.isRequired,
    handleIndexGet: PropTypes.func.isRequired,
    handleFileRetrieve: PropTypes.func.isRequired,
  }

  componentDidMount () {
    this.props.handleAddressGet()
    this.props.handleSizeGet()
  }

  getData () {
    const {
      IPFSStorage: {
        size
      },
      files
    } = this.props

    if (size && size != 0 && Object.keys(files).length == 0)
      for (let i = 0; i < size; i++)
        this.props.handleIndexGet(i)

    for (const k in files) {
      let item = files[k]
      if (item.index !== undefined && !item.retrieving && !item.retrieved) {
        this.props.handleFileRetrieve(k)
      }
    }
  }

  render () {
    return (
      <BrowserRouter >
        <Route exact path='/' component={Authenticate} />
      </BrowserRouter>
    )
  }

}

export default connect(mapStateToProps, mapDispatchToProps)(App)
