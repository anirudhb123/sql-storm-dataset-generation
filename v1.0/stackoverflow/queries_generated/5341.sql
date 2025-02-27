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
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(CASE WHEN h.PostHistoryTypeId = 4 THEN h.CreationDate END) AS AvgEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, 
        AnswerCount, CommentCount, FavoriteCount,
        OwnerDisplayName, TotalComments, TotalUpvotes, TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    tp.OwnerDisplayName,
    tp.TotalComments,
    tp.TotalUpvotes,
    tp.TotalDownvotes,
    CASE
        WHEN tp.Rank <= 10 THEN 'Top Post'
        WHEN tp.Rank <= 50 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    TopPosts tp
WHERE 
    tp.TotalComments > 5 AND tp.Score > 10
ORDER BY 
    tp.Rank;
