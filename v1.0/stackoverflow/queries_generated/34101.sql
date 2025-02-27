WITH RecursivePostChain AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.CreationDate,
        1 AS Level,
        p.OwnerUserId,
        p.Title,
        p.Score
    FROM Posts p
    WHERE p.PostTypeId = 2  -- Starting with Answers
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.CreationDate,
        rpc.Level + 1,
        p.OwnerUserId,
        p.Title,
        p.Score
    FROM Posts p
    INNER JOIN RecursivePostChain rpc ON p.Id = rpc.ParentId
)
SELECT 
    u.DisplayName AS Author,
    COUNT(DISTINCT rpc.PostId) AS AnswerCount,
    SUM(rpc.Score) AS TotalScore,
    MAX(p.CreationDate) AS LatestActivity,
    STRING_AGG(DISTINCT p.Tags, ', ') AS TagsUsed,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenCount,
    COALESCE(SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
FROM RecursivePostChain rpc
JOIN Posts p ON rpc.PostId = p.Id
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN PostHistory ph ON ph.PostId = p.Id
LEFT JOIN Badges b ON b.UserId = u.Id
WHERE u.Reputation > 1000  -- Filter only users with reputation above 1000
AND p.LastActivityDate >= NOW() - INTERVAL '1 year'  -- Consider posts from the last year
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT rpc.PostId) > 5  -- Only consider authors with more than 5 answers
ORDER BY TotalScore DESC
LIMIT 10;
