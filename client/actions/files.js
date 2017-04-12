import Request from 'superagent'

// Add a file
export const FILE_LOAD_PENDING = 'FILE_LOAD_PENDING'
export const FILE_LOAD_SUCCESS = 'FILE_LOAD_SUCCESS'
export const FILE_LOAD_ERROR   = 'FILE_LOAD_ERROR'

export const filesLoad = (files) => {
  return (dispatch) => {
    files.forEach(f => fileLoad(dispatch, f))
  }
}

const fileLoad = (dispatch, file) => {
  dispatch(fileLoadPending())
  const reader = new FileReader()
  reader.onload = (f) => {
    dispatch(fileLoadSuccess({
      name: file.name,
      content: f.target.result,
      type: file.type
    }))
  }
  reader.onerror = (error) => {
    dispatch(fileLoadError({
      error,
      name: file.name
    }))
  }
  reader.readAsDataURL(file)
}

const fileLoadPending = () => {
  return {
    type: FILE_LOAD_PENDING
  }
}

const fileLoadSuccess = (file) => {
  return {
    type: FILE_LOAD_SUCCESS,
    file
  }
}

const fileLoadError = (file) => {
  return {
    type: FILE_LOAD_ERROR,
    file
  }
}

// Submitting files to IPFS
export const FILE_SUBMIT_PENDING = 'FILE_SUBMIT_PENDING'
export const FILE_SUBMIT_SUCCESS = 'FILE_SUBMIT_SUCCESS'
export const FILE_SUBMIT_ERROR   = 'FILE_SUBMIT_ERROR'

export const filesSubmit = () => {
  return (dispatch, getState) => {
    getState().files.forEach((f, i) => fileSubmit(dispatch, f, i))
  }
}

const fileSubmit = (dispatch, file, index) => {
  dispatch(fileSubmitPending())
  Request
    .post(process.env.API_ENDPOINT + '/ipfs')
    .send(file)
    .end((err, res) => {
      if (err) {
        console.dir(err)
        dispatch(fileSubmitError(err))
      } else {
        console.dir(res)
        dispatch(fileSubmitSuccess(index))
      }
    })
}

const fileSubmitPending = () => {
  return {
    type: FILE_SUBMIT_PENDING
  }
}

const fileSubmitSuccess = (index) => {
  return {
    type: FILE_SUBMIT_SUCCESS,
    index
  }
}

const fileSubmitError = (error) => {
  return {
    type: FILE_SUBMIT_ERROR,
    error
  }
}