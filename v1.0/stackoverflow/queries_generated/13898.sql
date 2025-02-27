-- Performance benchmarking query for analyzing the posts and their related data
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter to posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC) AS RankByScore,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS RankByViews
    FROM 
        PostStats ps
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerDisplayName,
    UpVoteCount,
    DownVoteCount,
    RankByScore,
    RankByViews
FROM 
    TopPosts
WHERE 
    RankByScore <= 10 OR RankByViews <= 10  -- Display top 10 posts by score or views
ORDER BY 
    RankByScore, RankByViews;
