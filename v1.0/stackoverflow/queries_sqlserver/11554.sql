
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    p.ViewCount,
    p.Score,
    t.TagName
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    STRING_SPLIT(p.Tags, ',') AS t ON 1 = 1
WHERE
    p.PostTypeId = 1 
GROUP BY
    p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score, t.value
ORDER BY
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
