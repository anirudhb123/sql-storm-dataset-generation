WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS ScoreAdjustment
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),
AdjustedScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.ScoreAdjustment,
        (rp.ViewCount + rp.ScoreAdjustment) AS AdjustedScore
    FROM 
        RankedPosts rp
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        CommentCount,
        AdjustedScore,
        DENSE_RANK() OVER (ORDER BY AdjustedScore DESC) AS DenseRank
    FROM 
        AdjustedScores
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.AdjustedScore,
    (SELECT string_agg(t.TagName, ', ') 
     FROM Tags t 
     INNER JOIN Posts p ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[]) 
     WHERE p.Id = tp.PostId) AS AssociatedTags
FROM 
    TopPosts tp
WHERE 
    tp.CommentCount > 0
ORDER BY 
    tp.AdjustedScore DESC
LIMIT 20;

-- Notes:
-- 1. The query identifies top posts over the past year, adjusting scores based on votes and views.
-- 2. The use of CTE allows for clean separation of logic: ranking posts, adjusting scores, and then filtering for top posts.
-- 3. The final associated tags are gathered using a correlated subquery.
