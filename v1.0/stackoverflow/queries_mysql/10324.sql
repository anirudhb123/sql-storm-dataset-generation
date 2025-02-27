
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
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
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
    (SELECT DISTINCT tagId FROM 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) tagId
        FROM 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) as tagIds) as tagId ON tagId IS NOT NULL
LEFT JOIN
    Tags t ON t.TagName = tagId
GROUP BY
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, 
    u.Reputation, u.DisplayName, pt.Name
ORDER BY
    p.CreationDate DESC
LIMIT 100;
