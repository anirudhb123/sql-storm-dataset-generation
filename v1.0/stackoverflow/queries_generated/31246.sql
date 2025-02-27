WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullHierarchy
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        r.Level + 1,
        CAST(r.FullHierarchy + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.Id
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(p.Score) AS AverageScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(b.Name) AS HighestBadge,
    MIN(COALESCE(c.Text, 'No comments')) AS FirstComment,
    MAX(rp.FullHierarchy) AS PostHierarchy
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Comments c ON c.PostId = p.Id
LEFT JOIN RecursivePostCTE rp ON rp.OwnerUserId = u.Id
WHERE u.Reputation >= 1000
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT p.Id) > 10 
   AND MAX(p.CreationDate) < NOW() - INTERVAL '30 days'
ORDER BY TotalPosts DESC, TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- Additional Performance Benchmarking
EXPLAIN ANALYZE 
WITH PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
CombinedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM Posts p
    LEFT JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
)
SELECT 
    ScoreCategory,
    COUNT(*) AS PostCount,
    AVG(UpVotes) AS AverageUpVotes,
    AVG(DownVotes) AS AverageDownVotes
FROM CombinedPosts
GROUP BY ScoreCategory
ORDER BY PostCount DESC;

