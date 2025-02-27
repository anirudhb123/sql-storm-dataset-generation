WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > '2020-01-01' 
        AND p.ViewCount > 100
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS Popularity
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 5
    ORDER BY 
        Popularity DESC
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        pt.Popularity,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PostRank
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON pt.TagName IN (
            SELECT UNNEST(string_to_array(rp.Tags, '><')) 
            )
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.Popularity,
    pd.PostRank
FROM 
    PostDetails pd
WHERE 
    pd.PostRank <= 10
ORDER BY 
    pd.Popularity DESC, pd.ViewCount DESC;
