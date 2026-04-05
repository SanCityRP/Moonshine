Database = {}

function Database.Create(data)
    return MySQL.insert.await(
        'INSERT INTO moonshine_batches (owner, stage, data) VALUES (?, ?, ?)',
        { data.owner, data.stage, json.encode(data) }
    )
end

function Database.Update(id, data)
    MySQL.update(
        'UPDATE moonshine_batches SET stage = ?, data = ? WHERE id = ?',
        { data.stage, json.encode(data), id }
    )
end

function Database.LoadAll()
    local result = MySQL.query.await('SELECT * FROM moonshine_batches')
    for i = 1, #result do
        result[i].data = json.decode(result[i].data)
    end
    return result
end