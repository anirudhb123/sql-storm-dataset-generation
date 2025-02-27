
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.Reputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
TagStatistics AS (
    SELECT 
        TRIM(REPLACE(SUBSTRING(value, 2, LEN(value) - 2), '>', '')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '>') AS value
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(REPLACE(SUBSTRING(value, 2, LEN(value) - 2), '>', ''))
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Reputation,
    tt.TagName,
    tt.PostCount
FROM 
    TopPosts tp
JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(tp.Tags, '>'))
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
