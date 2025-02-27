WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpvotedPosts,
        DownvotedPosts,
        TotalBounty,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalBounty DESC) AS Rank
    FROM UserPostStats
),
TopPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        pt.Name AS PostType,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    u.DisplayName AS TopUser,
    u.PostCount,
    u.UpvotedPosts,
    u.DownvotedPosts,
    u.TotalBounty,
    u.LastPostDate,
    pp.PostId,
    pp.Title AS PostTitle,
    pp.Score,
    pp.CreationDate AS PostCreationDate,
    pp.Owner AS PostOwner,
    pp.PostType,
    pp.CommentCount
FROM TopUsers u
JOIN TopPostDetails pp ON u.UserId = pp.Owner
WHERE u.Rank <= 10
ORDER BY u.TotalBounty DESC, u.PostCount DESC;
