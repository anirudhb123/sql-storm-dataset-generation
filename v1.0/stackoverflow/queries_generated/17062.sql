SELECT
    Posts.Title,
    Posts.CreationDate,
    Users.DisplayName AS Author,
    Posts.Score,
    Posts.ViewCount,
    COUNT(Comments.Id) AS CommentCount
FROM
    Posts
JOIN
    Users ON Posts.OwnerUserId = Users.Id
LEFT JOIN
    Comments ON Posts.Id = Comments.PostId
WHERE
    Posts.PostTypeId = 1 -- Filter for Questions
GROUP BY
    Posts.Id, Users.DisplayName
ORDER BY
    Posts.Score DESC
LIMIT 10;
