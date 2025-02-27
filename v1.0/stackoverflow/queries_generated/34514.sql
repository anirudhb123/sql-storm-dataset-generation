WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        CAST(0 AS INT) AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.Score,
        p2.OwnerUserId,
        rp.Depth + 1
    FROM 
        Posts p2
    INNER JOIN 
        Posts p ON p2.ParentId = p.Id
    INNER JOIN 
        RecursivePosts rp ON p.Id = rp.Id
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AvgScore,
    COUNT(DISTINCT nec.Id) AS TotalCloseComments,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationTier,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsPredominantlyUsed,
    MAX(p.CreationDate) AS LastActiveDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    Comments nec ON nec.PostId = p.Id AND nec.CreationDate BETWEEN CURRENT_TIMESTAMP - INTERVAL '1 year' AND CURRENT_TIMESTAMP
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 0 AND SUM(p.Score) > 50
ORDER BY 
    TotalQuestions DESC, TotalScore DESC;

WITH LastVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY v.UserId ORDER BY v.CreationDate DESC) AS rn
    FROM 
        Votes v
)
SELECT 
    p.Title,
    COUNT(lv.UserId) AS TotalUniqueVoters,
    SUM(lv.CreationDate > p.CreationDate) AS VotedAfterCreated,
    SUM(CASE WHEN lv.UserId IS NOT NULL THEN 1 ELSE 0 END) AS UserVotesCount,
    p.ViewCount,
    p.Summary AS PostSummary
FROM 
    Posts p
LEFT JOIN 
    LastVotes lv ON p.Id = lv.PostId AND lv.rn = 1
WHERE 
    p.ViewCount IS NOT NULL
GROUP BY 
    p.Title, p.ViewCount, p.Summary
ORDER BY 
    TotalUniqueVoters DESC, p.ViewCount DESC;
