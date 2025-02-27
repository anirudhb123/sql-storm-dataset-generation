
WITH TagStats AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 
            a.N + b.N * 10 + 1 AS n 
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a 
        CROSS JOIN 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b 
    ) AS n
    WHERE
        PostTypeId = 1  
    GROUP BY
        Tag
),
PopularTags AS (
    SELECT
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM
        TagStats, (SELECT @rank := 0) r
    WHERE
        PostCount > 5  
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS Owner
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL 30 DAY  
        AND p.PostTypeId = 1  
),
TagPostMapping AS (
    SELECT
        tp.Tag AS PopularTag,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostType,
        rp.Owner
    FROM
        PopularTags tp
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%', tp.Tag, '%')
    JOIN
        RecentPosts rp ON rp.PostId = p.Id
),
FinalResults AS (
    SELECT
        tpm.PopularTag,
        COUNT(tpm.PostId) AS RelatedPostCount,
        GROUP_CONCAT(rp.Title SEPARATOR '; ') AS RelatedPostTitles,
        MAX(rp.CreationDate) AS LatestPostDate
    FROM
        TagPostMapping tpm
    JOIN
        RecentPosts rp ON tpm.PostId = rp.PostId
    GROUP BY
        tpm.PopularTag
)

SELECT
    *,
    DENSE_RANK() OVER (ORDER BY RelatedPostCount DESC) AS TagPopularityRank
FROM
    FinalResults
ORDER BY
    RelatedPostCount DESC;
