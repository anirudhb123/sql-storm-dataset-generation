WITH Recursive_Posts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Question

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.Score,
        a.CreationDate,
        a.ViewCount,
        a.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id -- Answers related to their Questions
    INNER JOIN 
        Recursive_Posts rp ON q.Id = rp.Id
)

SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.Score AS QuestionScore,
    p.ViewCount AS QuestionViews,
    u.DisplayName AS OwnerDisplayName,
    COUNT(a.Id) AS AnswerCount,
    SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
    ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
FROM 
    Recursive_Posts rp
INNER JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    Votes v ON a.Id = v.PostId AND v.VoteTypeId = 2 -- UpVotes
WHERE
    p.CreationDate BETWEEN NOW() - INTERVAL '30 DAYS' AND NOW() -- Filter questions from the last 30 days
GROUP BY 
    p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
HAVING 
    COUNT(a.Id) > 0 -- Only questions with answers
ORDER BY 
    TotalUpVotes DESC, QuestionScore DESC
LIMIT 10;

