-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
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
        us.TotalBounties,
        us.UpVotes,
        us.BadgeCount,
        ps.LastVoteDate
    FROM 
        PostStats ps
    JOIN 
        Users us ON ps.PostId = us.Id
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AnswerCount,
    us.DisplayName AS PostOwner,
    us.TotalBounties,
    us.UpVotes,
    us.BadgeCount,
    ps.LastVoteDate
FROM 
    PostSummary ps
JOIN 
    UserStats us ON ps.UserId = us.UserId
ORDER BY 
    ps.CreationDate DESC;
