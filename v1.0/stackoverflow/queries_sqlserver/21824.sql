
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountySum,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS tag
    LEFT JOIN Tags t ON tag.value = t.TagName
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        OwnerUserId AS UserId, 
        COUNT(*) AS RecentPostCount 
    FROM Posts 
    WHERE CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days')
    GROUP BY OwnerUserId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBountySum,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.CommentCount,
    pi.Tags,
    ra.RecentPostCount,
    CASE 
        WHEN ra.RecentPostCount IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM UserActivity ua
JOIN PostInfo pi ON ua.UserId = pi.PostId
LEFT JOIN RecentActivity ra ON ua.UserId = ra.UserId
WHERE ua.TotalPosts > 0
AND pi.UserPostRank <= 5
ORDER BY ua.TotalUpVotes DESC, pi.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
