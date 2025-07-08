
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
        p.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '1 year'
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
        TRIM(BOTH '<>' FROM VALUE) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(Tags, '>')) AS Tag
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(BOTH '<>' FROM VALUE)
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
    TopTags tt ON tt.TagName IN (SELECT TRIM(BOTH '<>' FROM VALUE) FROM LATERAL FLATTEN(INPUT => SPLIT(tp.Tags, '>')))
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
