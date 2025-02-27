
SELECT
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
WHERE
    p.PostTypeId = 1 
GROUP BY
    p.Id,
    p.Title,
    p.Score,
    u.DisplayName,
    p.CreationDate,
    p.ViewCount,
    p.AnswerCount
ORDER BY
    p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
