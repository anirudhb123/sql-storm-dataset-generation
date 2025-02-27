WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
        AND p.CreationDate >= DATEADD(year, -1, GETDATE())
),
PostTagCounts AS (
    SELECT 
        pt.PostId,
        COUNT(*) AS TagCount
    FROM 
        (SELECT 
             PostId, 
             unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
         FROM 
             Posts) pt
    GROUP BY 
        pt.PostId
),
PostAggregation AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(ptc.TagCount, 0) AS TagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTagCounts ptc ON rp.PostId = ptc.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Body,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.TagCount,
    COUNT(c.Id) AS CommentCount
FROM 
    PostAggregation pa
LEFT JOIN 
    Comments c ON pa.PostId = c.PostId
WHERE 
    pa.TagCount > 5
GROUP BY 
    pa.PostId, 
    pa.Title, 
    pa.Body, 
    pa.CreationDate, 
    pa.ViewCount, 
    pa.Score, 
    pa.TagCount
HAVING 
    COUNT(c.Id) > 2
ORDER BY 
    pa.Score DESC, 
    pa.ViewCount DESC;
