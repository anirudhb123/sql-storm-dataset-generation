
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMPADD(year, -1, '2024-10-01 12:34:56') 
        AND p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        r.*,
        CASE 
            WHEN r.RecentPostRank <= 5 THEN 'Top Recent'
            ELSE 'Older Posts'
        END AS PostCategory,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts r
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.ScoreRank <= 10 
),
SubqueryComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        LISTAGG(c.Text, '; ') WITHIN GROUP (ORDER BY c.Id) AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        f.Title,
        f.CreationDate,
        f.Score,
        f.ViewCount,
        f.PostCategory,
        COALESCE(sc.CommentCount, 0) AS TotalComments,
        COALESCE(sc.Comments, 'No comments') AS CommentTexts
    FROM 
        FilteredPosts f
    LEFT JOIN 
        SubqueryComments sc ON f.PostId = sc.PostId
    WHERE 
        f.PostCategory = 'Top Recent' 
        AND f.Score > (SELECT AVG(Score) FROM Posts) 
    ORDER BY 
        f.Score DESC
)

SELECT 
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.PostCategory,
    f.TotalComments,
    f.CommentTexts,
    CASE 
        WHEN f.Score IS NULL THEN 'Unknown Score'
        WHEN f.Score > 100 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS RatingCategory
FROM 
    FinalResults f
WHERE 
    f.TotalComments > 1 
    OR f.Score < 50
ORDER BY 
    f.Score DESC, f.CreationDate DESC
LIMIT 100;
