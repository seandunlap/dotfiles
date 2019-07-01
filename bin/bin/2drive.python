file_metadata = {
    'name': 'My Report',
    'mimeType': 'application/vnd.google-apps.spreadsheet'
}
media = MediaFileUpload('files/report.csv',
                        mimetype='text/csv',
                        resumable=True)
file = drive_service.files().create(body=file_metadata,
                                    media_body=media,
                                    fields='id').execute()
print 'File ID: %s' % file.get('id')
