WITH UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBounty
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBounty,
        Rank() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserReputationCTE
    WHERE TotalBounty > 0
),

PostsWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY p.Id, p.Title, p.ViewCount
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalBounty,
    COALESCE(p.PostCount, 0) AS PostCount,
    COALESCE(p.AvgBounty, 0) AS AvgBounty,
    pts.PostId,
    pts.Title,
    pts.ViewCount,
    pts.Tags
FROM TopUsers u
LEFT JOIN UserReputationCTE p ON u.UserId = p.UserId
LEFT JOIN PostsWithTags pts ON p.PostCount > 0 AND pts.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.UserId)
WHERE u.BountyRank <= 10
ORDER BY u.TotalBounty DESC, pts.ViewCount DESC;
