WITH RecursivePostCTE AS (
    -- Get all posts including their parent-child relationships
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    AVG(v.BountyAmount) AS AverageBounty,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(CASE 
        WHEN ph.UserId IS NOT NULL THEN 'Edited' 
        ELSE 'Not Edited' 
    END) AS EditStatus,
    COUNT(DISTINCT ph.Id) AS HistoryCount,
    ROW_NUMBER() OVER(PARTITION BY u.Id ORDER BY u.Reputation DESC) AS UserRank
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2  -- Answers
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id  -- Post history for edited status
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array  -- Tags
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId = 8 -- Bounty votes
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    u.Id, p.Title, p.CreationDate
HAVING 
    COUNT(DISTINCT a.Id) >= 3  -- Questions with at least 3 answers
ORDER BY 
    UserReputation DESC, AnswerCount DESC;
