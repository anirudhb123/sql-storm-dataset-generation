WITH RECURSIVE UserScoreCTE AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.CreationDate,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000  -- Initial filter for high reputation users
    UNION ALL
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.CreationDate,
        Level + 1
    FROM Users u
    INNER JOIN UserScoreCTE us ON u.Reputation < us.Reputation  -- Recursive join to find chaining of reputation levels
    WHERE Level < 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount, 
        SUM(v.CreationDate IS NOT NULL) AS Upvotes,
        SUM(v.VoteTypeId = 2) AS PositiveVotes,
        SUM(v.VoteTypeId = 3) AS NegativeVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Filter for recent posts
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.PostTypeId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        SUM(ps.Upvotes) AS TotalUpvotes,
        COUNT(DISTINCT ps.PostId) AS TotalPosts
    FROM UserScoreCTE us
    JOIN PostStats ps ON us.UserId = ps.OwnerUserId
    GROUP BY us.UserId, us.DisplayName
),
AggregatedData AS (
    SELECT 
        tu.DisplayName,
        tu.TotalUpvotes,
        tu.TotalPosts,
        CASE 
            WHEN tu.TotalPosts > 50 THEN 'High Contributor'
            WHEN tu.TotalPosts BETWEEN 20 AND 50 THEN 'Medium Contributor'
            ELSE 'Low Contributor'
        END AS ContributorTier
    FROM TopUsers tu
)
SELECT 
    ad.DisplayName,
    ad.TotalUpvotes,
    ad.TotalPosts,
    ad.ContributorTier,
    COUNT(DISTINCT ps.PostId) AS AssociatedPosts,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles
FROM AggregatedData ad
LEFT JOIN PostStats ps ON ad.UserId = ps.OwnerUserId
LEFT JOIN Posts p ON ps.PostId = p.Id
WHERE ad.TotalUpvotes > 100  -- Filtering for users with significant upvote counts
GROUP BY ad.DisplayName, ad.TotalUpvotes, ad.TotalPosts, ad.ContributorTier
ORDER BY ad.TotalUpvotes DESC, ad.TotalPosts DESC
LIMIT 10;
