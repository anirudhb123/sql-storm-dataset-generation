
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        UpvoteCount, 
        DownvoteCount,
        @row_number:=@row_number + 1 AS Rank
    FROM 
        RecentPosts, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Score DESC, ViewCount DESC, CommentCount DESC
)
SELECT 
    tp.*, 
    CASE 
        WHEN tp.Score > 100 THEN 'Hot' 
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
