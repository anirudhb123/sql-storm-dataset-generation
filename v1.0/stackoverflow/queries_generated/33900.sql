WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    
    UNION ALL
    
    SELECT 
        a.Id AS PostId,
        a.ParentId,
        a.Title,
        a.CreationDate,
        Level + 1
    FROM 
        Posts a
    INNER JOIN RecursivePostCTE r ON a.ParentId = r.PostId
)

SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    COALESCE(au.UpVotes, 0) AS QuestionsUpVotes,
    COALESCE(au.DownVotes, 0) AS QuestionsDownVotes,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    NULLIF(SUM(v.BountyAmount), 0) AS TotalBountyAmount
FROM 
    Posts p
LEFT JOIN 
    RecursivePostCTE r ON p.Id = r.PostId
LEFT JOIN 
    Users au ON p.OwnerUserId = au.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2  -- Join Answers
LEFT JOIN 
    Comments c ON c.PostId = p.Id  -- Join Comments
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id  -- Join Post Links
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 10)  -- Join Bounty and Deletion votes
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id  -- Join Tags
WHERE 
    p.PostTypeId = 1  -- Ensuring we only focus on Questions
    AND p.CreationDate > DATEADD(YEAR, -2, GETDATE())  -- Only include questions created in the last two years
GROUP BY 
    p.Id, p.Title, p.CreationDate, au.UpVotes, au.DownVotes
ORDER BY 
    TotalBountyAmount DESC NULLS LAST, 
    QuestionsUpVotes DESC, 
    AnswerCount DESC;

### Query Breakdown:
- **Recursive CTE:** Collects all questions and their respective answers.
- **Tags and Votes:** Aggregate tags associated with questions and sum bounties to assess engagement.
- **Validations:** Use COALESCE and NULLIF to manage potential NULL values in upvotes, downvotes, and total bounties.
- **Filtering and Ordering:** Focus on questions within the last two years and sort results based on the total bounty, prioritizing active questions with higher engagement. 

This query combines various SQL elements like CTEs, aggregate functions, outer joins, and conditional logic to provide a comprehensive view of question performance in a Stack Overflow-like schema.
