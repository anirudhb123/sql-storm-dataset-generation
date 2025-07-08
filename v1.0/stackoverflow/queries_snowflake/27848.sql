
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount,
        (
            SELECT COUNT(*)
            FROM PostHistory ph
            WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)
        ) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01'::date)
),
TagFrequency AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    CROSS JOIN 
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><'))) AS t
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.CloseReopenCount,
    tt.Tag,
    tt.Frequency AS TagFrequency
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.UserPostRank = 1
WHERE 
    tt.TagRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
