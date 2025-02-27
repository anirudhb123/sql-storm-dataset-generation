WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        AVG(COALESCE(DATE_PART('epoch', p.LastActivityDate - p.CreationDate), 0)) AS AvgPostLifeInSeconds
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),

TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.PostCount,
        ue.CommentCount,
        ue.BadgeCount,
        ue.UpVotesReceived,
        ue.DownVotesReceived,
        RANK() OVER (ORDER BY ue.Reputation DESC) AS UserRank
    FROM UserEngagement ue
    WHERE ue.UpVotesReceived - ue.DownVotesReceived > 10
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.CommentCount,
    tu.BadgeCount,
    tu.UserRank,
    CASE 
        WHEN tu.BadgeCount = 0 THEN 'No Badges'
        WHEN tu.BadgeCount BETWEEN 1 AND 3 THEN 'Bronze Level'
        WHEN tu.BadgeCount BETWEEN 4 AND 6 THEN 'Silver Level'
        ELSE 'Gold Level' 
    END AS BadgeLevel
FROM TopUsers tu
WHERE tu.UserRank <= 25
ORDER BY tu.UserRank;

-- Additional Performance Enhancement through CTE for testing NULL handling
, PostStatistics AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.Score IS NULL THEN 1 ELSE 0 END) AS NullScorePosts,
        SUM(p.ViewCount) AS TotalViews,
        BOOL_AND(p.ClosedDate IS NOT NULL) AS AllPostsClosed,
        STRING_AGG(DISTINCT CASE WHEN p.Tags IS NOT NULL THEN p.Tags END, ',') AS UniqueTags
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.PostTypeId
)

SELECT 
    ps.PostTypeId,
    ps.TotalPosts,
    ps.NullScorePosts,
    ps.TotalViews,
    ps.AllPostsClosed,
    ps.UniqueTags
FROM PostStatistics ps
WHERE ps.TotalPosts > 10
ORDER BY ps.TotalViews DESC;

-- Final Benchmarking Results
;WITH FinalReport AS (
    SELECT 
        ue.UserId,
        COUNT(ps.TotalPosts) AS PostsInLastYear,
        SUM(ps.TotalViews) AS ViewsInLastYear,
        SUM(CASE WHEN ps.NullScorePosts > 0 THEN 1 ELSE 0 END) AS UsersWithNullScores
    FROM UserEngagement ue
    JOIN PostStatistics ps ON ue.PostCount > 5
    GROUP BY ue.UserId
)

SELECT 
    UserId,
    PostsInLastYear,
    ViewsInLastYear,
    UsersWithNullScores
FROM FinalReport
WHERE ViewsInLastYear > 1000
ORDER BY ViewsInLastYear DESC 
LIMIT 10;
