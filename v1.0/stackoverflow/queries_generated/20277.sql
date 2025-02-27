WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate ASC) AS CreationRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '365 days')
),
TopPosts AS (
    SELECT 
        rp.*,
        COUNT(c.Id) FILTER (WHERE c.Score >= 0) AS PositiveComments,
        COUNT(DISTINCT v.UserId) AS UniqueUpvoters
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId = 2  -- Upvotes
    WHERE 
        rp.RankScore <= 5
    GROUP BY 
        rp.PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.AnswerCount,
        tp.PositiveComments,
        tp.UniqueUpvoters,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)), 0) AS TotalBadgeClass,
        (SELECT COUNT(DISTINCT pl.RelatedPostId) FROM PostLinks pl WHERE pl.PostId = tp.PostId) AS RelatedPostCount
    FROM 
        TopPosts tp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.PositiveComments,
    pd.UniqueUpvoters,
    pd.TotalBadgeClass,
    pd.RelatedPostCount,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score'
        WHEN pd.Score > 10 THEN 'High Score'
        ELSE 'Moderate Score'
    END AS ScoreCategory,
    CASE 
        WHEN pd.ViewCount IS NULL THEN 'Unseen'
        WHEN pd.ViewCount > 1000 THEN 'Trending'
        ELSE 'Normal'
    END AS TrendStatus
FROM 
    PostDetails pd
WHERE 
    (pd.TotalBadgeClass > 10 OR pd.ViewCount > 500)
    AND pd.UniqueUpvoters > 2
ORDER BY 
    pd.Score DESC NULLS LAST, 
    pd.ViewCount DESC;

### Explanation of Constructs Used:

1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts`: Ranks posts based on their score and assigns creation rank over the last year.
   - `TopPosts`: Aggregates data regarding comments and unique upvoters for top-ranked posts.
   - `PostDetails`: Gathers detailed information, including badge classification and the count of related posts.

2. **Window Functions**: 
   - `ROW_NUMBER()` and `DENSE_RANK()` provide row numbering based on specified conditions for analytical insights.

3. **Outer Joins**: 
   - LEFT JOINs connect comments and votes to ensure all posts are included regardless of associated comments or votes.

4. **Filter Clauses**: 
   - COUNTs with `FILTER` to segregate positive comments.

5. **Subqueries**: 
   - Used for aggregating badge classes and related post counts.

6. **NULL Logic**: 
   - Uses `COALESCE()` to handle cases where badge data might not be present.

7. **Complicated Predicates**: 
   - CASE constructs categorize score and view count with complex logic.

8. **String Functions**: 
   - Not explicitly present as part of this sample; however, many constructs prioritize clarity and aggregational granularity.

9. **Bizarre Semantics**: 
   - Utilizes nullable checks and extreme scoring distinctions that could present edge cases in how data is interpreted (no score vs. high score).

This SQL query is designed for performance testing due to its complexity, leveraging advanced SQL techniques to benchmark various dimensions of post engagement data.
