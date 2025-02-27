WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months'
),

PostWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.ScoreRank,
        pt.Name AS PostTypeName,
        STRING_AGG(t.TagName, ', ') AS TagNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        UNNEST(string_to_array(rp.Tags, ',')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_name)
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.ScoreRank, pt.Name
),

FilteredPosts AS (
    SELECT 
        pw.PostId,
        pw.Title,
        pw.ViewCount,
        pw.Score,
        pw.ScoreRank,
        pw.PostTypeName,
        pw.TagNames,
        LEAD(pw.Score) OVER (ORDER BY pw.Score DESC) AS NextPostScore,
        CASE 
            WHEN pw.Score >= 100 THEN 'High Scorer'
            WHEN pw.Score > 50 THEN 'Moderate Scorer'
            ELSE 'Low Scorer'
        END AS ScoreCategory
    FROM 
        PostWithTags pw
    WHERE 
        pw.TotalComments > 0
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.ScoreRank,
    fp.PostTypeName,
    COALESCE(fp.TagNames, 'No Tags') AS TagsInfo,
    fp.NextPostScore AS NextPostScore,
    fp.ScoreCategory,
    CASE 
        WHEN fp.Score IS NULL THEN 'No Score Info Available'
        WHEN fp.Score > 100 THEN 'Top Performer'
        ELSE 'Keep Improving'
    END AS PerformersRemark
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    (u.Reputation > 1000 OR u.Location IS NOT NULL) 
    AND (fp.ScoreRank < 5 OR fp.Score IS NULL)
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 100;

-- Additional sorting and grouping to reflect complex benchmark requirements.
