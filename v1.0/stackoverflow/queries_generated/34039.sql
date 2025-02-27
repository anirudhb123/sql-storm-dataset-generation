WITH RecursivePostCTE AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE cte ON a.ParentId = cte.PostId
)
SELECT 
    p.Title AS QuestionTitle,
    p.ViewCount AS QuestionViews,
    COALESCE(a.Title, '(No accepted answer)') AS AcceptedAnswerTitle,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(COALESCE(v.BountyAmount,0)) AS TotalBounty,
    DENSE_RANK() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS LastCommentRank
FROM 
    RecursivePostCTE p
LEFT JOIN 
    Posts a ON p.AcceptedAnswerId = a.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
WHERE 
    p.ViewCount > 100
GROUP BY 
    p.PostId, p.Title, p.ViewCount, a.Title, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT c.Id) > 0 OR SUM(COALESCE(v.BountyAmount,0)) > 0
ORDER BY 
    p.ViewCount DESC, UserReputation DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
