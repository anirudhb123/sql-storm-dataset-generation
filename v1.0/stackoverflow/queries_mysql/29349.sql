
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
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
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
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
    TopTags tt ON FIND_IN_SET(tt.TagName, REPLACE(tp.Tags, '>', ',')) > 0
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
