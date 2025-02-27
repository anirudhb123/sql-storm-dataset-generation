-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.CreationDate IS NOT NULL AND vt.Id = 2) AS UpVoteCount, -- UpVotes
        SUM(v.CreationDate IS NOT NULL AND vt.Id = 3) AS DownVoteCount -- DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.Score, 0) as Score,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(p.FavoriteCount, 0) as FavoriteCount,
        COALESCE(p.ClosedDate, p.CreationDate) AS CloseDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' -- considering last month posts
)
SELECT 
    u.DisplayName,
    ups.PostCount,
    ups.CommentCount,
    ups.UpVoteCount,
    ups.DownVoteCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount AS PostCommentCount,
    ps.FavoriteCount,
    ps.CloseDate
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    PostSummary ps ON u.Id = ps.OwnerUserId
ORDER BY 
    ups.PostCount DESC, 
    ups.UpVoteCount DESC;
