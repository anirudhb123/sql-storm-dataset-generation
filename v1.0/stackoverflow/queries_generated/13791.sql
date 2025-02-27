-- Performance benchmarking query to evaluate post statistics and user activities

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2020-01-01' -- Filtering posts created since 2020
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT b.Id) AS BadgesEarned,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= '2020-01-01' -- Filtering users created since 2020
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.UserId,
    us.DisplayName AS UserDisplayName,
    us.PostsCreated,
    us.BadgesEarned,
    us.TotalBountyAmount
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = us.UserId  -- Assuming correlation between posts and user
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC; -- Ordering by score and view count for benchmarking performance
