WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS Level
    FROM Tags
    WHERE Count > 0
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rth ON t.ExcerptPostId = rth.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostClosedCount AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(*) AS ClosedPostCount
    FROM Posts p
    WHERE p.Id IN (
        SELECT ph.PostId 
        FROM PostHistory ph 
        WHERE ph.PostHistoryTypeId = 10
    )
    GROUP BY p.OwnerUserId
),
CombinedUserStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalBounties,
        ua.Upvotes,
        ua.Downvotes,
        COALESCE(pc.ClosedPostCount, 0) AS ClosedPostCount
    FROM UserActivity ua
    LEFT JOIN PostClosedCount pc ON ua.UserId = pc.UserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounties,
        Upvotes,
        Downvotes,
        ClosedPostCount,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM CombinedUserStats
)
SELECT 
    t.TagName,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounties,
    (tu.Upvotes - tu.Downvotes) AS NetVotes,
    tu.ClosedPostCount,
    CASE 
        WHEN tu.ClosedPostCount > 0 THEN 'Closed Posters - Active'
        ELSE 'Active but No Closed Posts'
    END AS Status
FROM RecursiveTagHierarchy t
JOIN TopUsers tu ON tu.PostCount > 0
WHERE t.Count > 5 AND tu.Rank <= 10
ORDER BY t.TagName, NetVotes DESC;
