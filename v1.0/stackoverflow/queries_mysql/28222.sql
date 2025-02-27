
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
        (SELECT COUNT(*) FROM (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
            FROM (SELECT a.N + b.N * 10 + 1 AS n
                  FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                 (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
            WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tmp
        ) AS TagList) AS TagCount
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagFrequency
    FROM
        Posts
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
          SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    WHERE
        PostTypeId = 1
    GROUP BY
        Tag
    ORDER BY
        TagFrequency DESC
    LIMIT 10
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
        PopularTags pt ON pt.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '><', -1)
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
