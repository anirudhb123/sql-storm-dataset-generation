WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts)
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        UserId,
        MAX(LastEditDate) AS MostRecentEdit,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalCloseReopen
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalComments,
        us.TotalUpVotes,
        us.TotalDownVotes,
        ra.MostRecentEdit,
        ra.TotalCloseReopen
    FROM 
        UserStats us
    JOIN 
        RecentActivity ra ON us.UserId = ra.UserId
    WHERE 
        us.Reputation > 100 AND (us.TotalPosts + us.TotalComments) > 10
    ORDER BY 
        us.TotalUpVotes DESC, ra.MostRecentEdit DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    COALESCE(ub.Badges, 'No Badges') AS Badges,
    tu.MostRecentEdit,
    tu.TotalCloseReopen
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
ORDER BY 
    tu.TotalUpVotes DESC, tu.TotalComments DESC;

This SQL query combines complex constructs to achieve the following: 

1. A Common Table Expression (CTE) named `UserStats` gathers statistics about users, including their post and comment counts, as well as votes. 
2. Another CTE (`RecentActivity`) tracks the most recent post edits and counts how often users close or reopen posts.
3. The `TopUsers` CTE identifies top users by applying specific filters on their reputation and activity level.
4. A final CTE (`UserBadges`) aggregates badges held by users.
5. The final selection retrieves user details, summarizing their achievements and recent activity, ordering the results by total upvotes and comments.

This structured query highlights advanced SQL features and demonstrates the ability to handle intricate relationships and conditions within the dataset.

