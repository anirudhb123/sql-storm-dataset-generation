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
    p.PostTypeId = 1 -- Only select questions
ORDER BY
    p.Score DESC
LIMIT 10; -- Get top 10 questions by score
