
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><')) AS TagCount
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1  
        AND u.Reputation > 50  
),
PopularTags AS (
    SELECT
        value AS Tag,
        COUNT(*) AS TagFrequency
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '><')
    WHERE
        PostTypeId = 1
    GROUP BY
        value
    ORDER BY
        TagFrequency DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        pt.Tag AS PopularTag
    FROM
        RankedPosts rp
    JOIN
        PopularTags pt ON pt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags)-2), '><'))
    WHERE
        rp.Rank = 1  
)

SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagCount,
    pd.PopularTag
FROM
    PostDetails pd
ORDER BY
    pd.Score DESC, pd.ViewCount DESC;
