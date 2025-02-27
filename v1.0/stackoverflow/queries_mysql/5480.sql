
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        CommentCount, 
        HighestBadgeClass,
        @row_number := IF(@prev_score = Score AND @prev_view_count = ViewCount, @row_number + 1, 1) AS Rank,
        @prev_score := Score,
        @prev_view_count := ViewCount
    FROM 
        RankedPosts, (SELECT @row_number := 0, @prev_score := NULL, @prev_view_count := NULL) AS vars
    ORDER BY 
        Score DESC, ViewCount DESC
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.CommentCount, 
    CASE 
        WHEN tp.HighestBadgeClass = 1 THEN 'Gold'
        WHEN tp.HighestBadgeClass = 2 THEN 'Silver'
        WHEN tp.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeLevel
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
