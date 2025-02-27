WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        ROW_NUMBER() OVER(PARTITION BY u.Id ORDER BY b.Date DESC) AS Rank
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(p.LastActivityDate) AS LastActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2020-01-01' -- Only consider posts created in 2020 and later
    GROUP BY p.Id, p.OwnerUserId, p.Title
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(po.ViewCount) AS TotalViews,
        SUM(po.CommentCount) AS TotalComments,
        SUM(po.UpVotes) AS TotalUpVotes,
        SUM(po.DownVotes) AS TotalDownVotes
    FROM Users u
    JOIN Posts po ON u.Id = po.OwnerUserId
    LEFT JOIN PostStats ps ON po.Id = ps.PostId
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(po.ViewCount) > 1000 -- Consider only users with more than 1000 views
),
FinalResult AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        tb.BadgeName,
        tb.Class,
        t.TotalViews,
        t.TotalComments,
        t.TotalUpVotes,
        t.TotalDownVotes,
        ROW_NUMBER() OVER(ORDER BY t.TotalUpVotes DESC) AS UserRank
    FROM TopUsers t
    LEFT JOIN UserBadges tb ON t.UserId = tb.UserId AND tb.Rank = 1 -- Join to get the latest badge
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.BadgeName,
    r.Class,
    r.TotalViews,
    r.TotalComments,
    r.TotalUpVotes,
    r.TotalDownVotes,
    CASE 
        WHEN r.UserRank <= 10 THEN 'Top Contributor' 
        ELSE 'Regular Contributor' 
    END AS ContributorType
FROM FinalResult r
ORDER BY r.TotalUpVotes DESC
LIMIT 50;

This SQL query is designed to analyze user contributions on a Stack Overflow-like platform, focusing particularly on users' badges and post statistics. Here’s a summary of the query breakdown:

1. **CTE - UserBadges**: This recursive common table expression collects badge information for each user, assigning a rank based on the date the badge was earned.

2. **CTE - PostStats**: This CTE aggregates post information, including comment counts and vote counts on posts created from the year 2020 onwards, through the use of outer joins.

3. **CTE - TopUsers**: This CTE calculates overall user metrics, filtering to include only users with a significant number of views (more than 1000).

4. **FinalResult CTE**: This CTE combines the top users with their most recent badge and ranks them based on their total upvotes received.

5. **Final SELECT**: The final result generates a list of users displaying contributor types and limiting the result set to the top 50 users based on upvotes, along with relevant details like badge and contribution statistics.
