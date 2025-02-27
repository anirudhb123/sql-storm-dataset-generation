WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY(
            SELECT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
            )::varchar
        ) AS TagsArray,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0
        AND p.CreationDate > NOW() - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        STRING_AGG(DISTINCT tag, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Author, rp.CreationDate, rp.Score, rp.ViewCount
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.Author,
    ad.CreationDate,
    ad.Score,
    ad.ViewCount,
    ad.Tags,
    ad.CommentCount,
    CASE 
        WHEN ad.Score > 100 THEN 'Highly Popular'
        WHEN ad.Score BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityRating
FROM 
    AggregatedData ad
WHERE 
    ad.Rank <= 10  -- Top 10 posts by score within the last year
ORDER BY 
    ad.Score DESC, 
    ad.ViewCount DESC;
