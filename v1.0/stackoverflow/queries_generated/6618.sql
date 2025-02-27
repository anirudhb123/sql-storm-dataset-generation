WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.LikeCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS DateRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        CASE 
            WHEN rp.ScoreRank <= 10 THEN 'Top Scoring'
            WHEN rp.DateRank <= 10 THEN 'Most Recent'
            ELSE 'Others'
        END AS Category
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10 OR rp.DateRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.Category,
    CASE 
        WHEN tp.Category = 'Top Scoring' THEN 'This post is among the highest scored in its category.'
        WHEN tp.Category = 'Most Recent' THEN 'This post is among the most recently created.'
        ELSE 'This post does not belong to top categories.'
    END AS CategoryMessage
FROM 
    TopPosts tp
ORDER BY 
    tp.Category, tp.Score DESC;
