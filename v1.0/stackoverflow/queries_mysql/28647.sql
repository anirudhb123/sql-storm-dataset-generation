
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
),
PostTags AS (
    SELECT 
        tp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        TopPosts tp
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '><', '')) >= numbers.n - 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    COUNT(pt.TagName) AS TagCount,
    GROUP_CONCAT(DISTINCT pt.TagName) AS AssociatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTags pt ON tp.PostId = pt.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 25;
