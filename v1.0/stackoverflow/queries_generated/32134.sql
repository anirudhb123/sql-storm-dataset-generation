WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AnswerCount, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id, 
        pp.Title, 
        pp.CreationDate, 
        pp.Score, 
        pp.AnswerCount, 
        Level + 1
    FROM 
        Posts pp
    INNER JOIN 
        RecursivePostCTE r ON pp.ParentId = r.PostId
    WHERE 
        pp.PostTypeId = 2 -- Only Answers
)
SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    COALESCE(a.AnswerCount, 0) AS TotalAnswers,
    COALESCE(u.DisplayName, 'Anonymous') AS AnswerOwner,
    a.CreationDate AS AnswerCreationDate,
    r.Level AS AnswerLevel,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.PostId
LEFT JOIN 
    Users u ON r.PostId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
LEFT JOIN 
    LATERAL (
        SELECT 
            COUNT(*) AS AnswerCount
        FROM 
            Posts ans
        WHERE 
            ans.ParentId = p.Id AND ans.PostTypeId = 2
    ) a ON TRUE
LEFT JOIN 
    PostsTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Id, p.Title, u.DisplayName, a.CreationDate, r.Level
ORDER BY 
    COUNT(v.Id) DESC, 
    p.CreationDate DESC
LIMIT 100;

This SQL query involves several components. It utilizes a recursive Common Table Expression (CTE) to relate questions to their answers while keeping track of the answer level. It also includes various types of JOINs (LEFT JOINs to incorporate optional relationships), aggregates vote counts, and combines tag information into a single field. Further, it encompasses COALESCE for handling NULL values in user display names. The final results are sorted by vote counts and creation date, providing a comprehensive overview of questions along with their answers and related metadata.
