-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Assuming PostTypeId = 2 is an Answer
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AnswerCount,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBounty,
    us.UpVoteCount,
    us.DownVoteCount
FROM 
    PostStats ps
JOIN 
    Users us ON ps.OwnerUserId = us.Id
ORDER BY 
    ps.ViewCount DESC
OPTION (QUERYTRACEON 9481); -- Enabling query optimization for performance 
