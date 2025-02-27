WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, Score, OwnerUserId
    FROM Posts
    WHERE ParentId IS NULL -- Start with root posts (Questions)
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, p.Score, p.OwnerUserId
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id -- Join to find children (Answers)
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        PositivePosts,
        NegativePosts,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS RankReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS RankPostCount
    FROM UserStatistics
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, -- Upvotes
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes -- Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days' -- Filter for recent posts
    GROUP BY p.Id, p.Title, p.CreationDate
),
CombinedResults AS (
    SELECT 
        u.DisplayName AS TopUser,
        t.Reputation AS TopUserReputation,
        rp.Title AS RecentPostTitle,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        u.PostCount AS TotalPosts
    FROM TopUsers t
    CROSS JOIN RecentPostActivity rp
    JOIN Users u ON t.UserId = u.Id
)
SELECT 
    r.TopUser,
    r.TopUserReputation,
    r.RecentPostTitle,
    COALESCE(r.CommentCount, 0) AS TotalComments,
    COALESCE(r.UpVotes, 0) AS TotalUpVotes,
    COALESCE(r.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN r.UpVotes + r.DownVotes > 0 THEN ROUND((r.UpVotes::DECIMAL / (r.UpVotes + r.DownVotes)) * 100, 2) 
        ELSE 0 
    END AS UpvotePercentage,
    CASE 
        WHEN r.CommentCount IS NULL THEN 'No comments yet.' 
        ELSE 'Comments available' 
    END AS CommentStatus
FROM CombinedResults r
WHERE r.TopUserReputation > 1000 -- Filtering for users with reputation greater than 1000
ORDER BY r.TopUserReputation DESC, r.CommentCount DESC;

