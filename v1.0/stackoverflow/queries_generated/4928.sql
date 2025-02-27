WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(v.BountyAmount) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(DISTINCT ph.Id) AS CloseCount
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id, p.Title
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    COALESCE(cp.LastClosedDate, 'No Closure') AS LastClosedDate,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    pt.TagName,
    pt.PostCount
FROM UserActivity ua
JOIN Users u ON ua.UserId = u.Id
LEFT JOIN ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN PopularTags pt ON pt.PostCount > 5
WHERE ua.ActivityRank <= 10
ORDER BY ua.TotalBounty DESC, u.DisplayName;
