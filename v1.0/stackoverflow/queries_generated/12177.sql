-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        COALESCE(ph.UserDisplayName, 'None') AS LastEditor
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate IS NOT NULL
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.CommentCount,
    ua.TotalBounty,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.LastEditor
FROM 
    UserActivity ua
JOIN 
    PostStats ps ON ua.UserId = ps.Id
ORDER BY 
    ua.PostCount DESC, ua.CommentCount DESC;
