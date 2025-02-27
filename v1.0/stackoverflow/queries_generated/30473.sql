WITH RecursivePostTree AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        rt.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostTree rt ON p.ParentId = rt.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS AnswerCount,
    AVG(v.BountyAmount) AS AvgBounty,
    MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS HasGoldBadge,
    MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS HasSilverBadge,
    MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS HasBronzeBadge,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2  -- Answers
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) -- Count of Bounty Start/Close
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Posts tp ON tp.Id IN (SELECT ParentId FROM RecursivePostTree WHERE PostId = p.Id)
LEFT JOIN 
    STRING_TO_ARRAY(tp.Tags, ',') AS t ON TRUE -- To split tags

WHERE 
    u.Reputation > 100 AND 
    p.CreationDate > NOW() - INTERVAL '1 YEAR' 
GROUP BY 
    u.Id
HAVING 
    COUNT(p.Id) > 3
ORDER BY 
    AVG(v.BountyAmount) DESC, u.Reputation DESC
LIMIT 50;
