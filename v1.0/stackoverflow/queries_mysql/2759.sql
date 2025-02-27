
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        @row_num := IF(@prev_post_type_id = p.PostTypeId, @row_num + 1, 1) AS RowNum,
        @prev_post_type_id := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_num := 0, @prev_post_type_id := NULL) AS vars
    WHERE 
        p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        pv.VoteScore,
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId,
        (SELECT @overall_rank := 0) AS ranks
    ORDER BY 
        COALESCE(pv.VoteScore, 0) DESC, rp.Score DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(tp.VoteScore, 0) AS VoteScore,
    CASE 
        WHEN tp.OverallRank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS RankCategory
FROM 
    TopPosts tp
WHERE 
    tp.CommentCount > 0 OR tp.VoteScore IS NOT NULL
ORDER BY 
    tp.OverallRank;
