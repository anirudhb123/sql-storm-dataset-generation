
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    pt.Name AS PostTypeName,
    LISTAGG(DISTINCT t.TagName, ',') AS Tags
FROM
    Posts p
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    LATERAL FLATTEN(input => SPLIT(p.Tags, '>')) AS tagId ON tagId.VALUE IS NOT NULL
LEFT JOIN
    Tags t ON t.TagName = tagId.VALUE
GROUP BY
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
    u.Reputation, u.DisplayName, pt.Name
ORDER BY
    p.CreationDate DESC
LIMIT 100;
