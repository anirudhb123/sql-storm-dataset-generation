WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        CASE
            WHEN p.AwardDate IS NOT NULL THEN DENSE_RANK() OVER (PARTITION BY p.Title ORDER BY p.AwardDate)
            ELSE NULL
        END AS AwardRank,
        DATEDIFF(day, p.CreationDate, GETDATE()) AS DaysSinceCreation
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalBounty,
    ur.ReputationRank,
    ts.TagName,
    ts.PostCount,
    ts.TotalViewCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerName,
    pd.AwardRank,
    CASE 
        WHEN pd.DaysSinceCreation < 30 THEN 'New' 
        WHEN pd.DaysSinceCreation BETWEEN 30 AND 90 THEN 'Moderate' 
        ELSE 'Old' 
    END AS PostAgeCategory,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount   
FROM UserReputation ur
LEFT JOIN TagStatistics ts ON ts.PostCount > 0
LEFT JOIN PostDetail pd ON ur.UserId = pd.OwnerName
LEFT JOIN Comments c ON c.PostId = pd.PostId
LEFT JOIN PostHistory ph ON ph.PostId = pd.PostId
GROUP BY 
    ur.UserId, ur.DisplayName, ur.TotalBounty, ur.ReputationRank, 
    ts.TagName, ts.PostCount, ts.TotalViewCount, 
    pd.PostId, pd.Title, pd.CreationDate, pd.OwnerName, 
    pd.AwardRank
ORDER BY ur.ReputationRank, ts.TotalViewCount DESC
LIMIT 100 OFFSET 50;
