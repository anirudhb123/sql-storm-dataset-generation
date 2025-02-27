-- Performance Benchmarking Query
WITH MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    mau.DisplayName,
    mau.VoteCount,
    mau.CommentCount AS UserCommentCount,
    mau.BadgeCount,
    mau.TotalViews,
    ps.PostId,
    ps.CommentCount AS PostCommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount
FROM 
    MostActiveUsers mau
JOIN 
    PostStats ps ON mau.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
ORDER BY 
    mau.TotalViews DESC, ps.UpVoteCount DESC, ps.PostCommentCount DESC;
