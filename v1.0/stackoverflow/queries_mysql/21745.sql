
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(tags) - CHAR_LENGTH(REPLACE(tags, '>', '')) >= numbers.n - 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerReputation,
    cp.CloseReason,
    pt.Tag,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1) 
                                  FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                                        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                                        SELECT 9 UNION ALL SELECT 10) numbers 
                                  WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1)
WHERE 
    rp.PostRank <= 5
    AND (rp.OwnerReputation IS NULL OR rp.OwnerReputation > 0)
    AND ((rp.Score > 10 OR cp.CloseReason IS NOT NULL)
    OR EXISTS (
        SELECT 1
        FROM Votes v 
        WHERE v.PostId = rp.PostId 
          AND v.UserId IS NULL
    ))
ORDER BY 
    COALESCE(rp.Score, 0) DESC,
    rp.CreationDate ASC;
