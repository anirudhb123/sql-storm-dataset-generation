WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL 
), 
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(u.DisplayName, 'Unknown User') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON rp.PostId = c.PostId
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        (rp.RankByScore = 1 OR rp.RankByDate = 1)
), 
TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '>'))) ) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
), 
Combined AS (
    SELECT 
        pwc.PostId,
        pwc.Title,
        pwc.CreationDate,
        pwc.ViewCount,
        pwc.Score,
        pwc.CommentCount,
        tc.TagName,
        tc.PostCount
    FROM 
        PostWithComments pwc
    LEFT JOIN 
        TagCounts tc ON pwc.PostId = tc.PostCount
)

SELECT 
    DISTINCT c.OwnerDisplayName, 
    c.Title,
    c.CreationDate,
    c.ViewCount,
    c.Score,
    c.CommentCount,
    c.TagName,
    CASE 
        WHEN c.PostCount IS NULL THEN 'No Posts for Tag'
        ELSE 'Total Posts: ' || c.PostCount::text 
    END AS TagStatistics
FROM 
    Combined c
WHERE 
    c.Score > 10 AND 
    c.CommentCount IS NOT NULL 
ORDER BY 
    c.CreationDate DESC NULLS LAST,
    c.Score DESC;
