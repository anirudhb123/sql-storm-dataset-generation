-- Performance benchmarking query for the StackOverflow schema
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.CommentCount, 
    ps.VoteCount, 
    ps.UpVoteCount, 
    ps.DownVoteCount,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalPostViews
FROM 
    PostStats ps
JOIN 
    Users us ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
ORDER BY 
    ps.PostId;
