
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
TagStatistics AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViews,
        AVG(Score) AS AvgScore
    FROM 
        TagStatistics 
    JOIN 
        RankedPosts ON FIND_IN_SET(Tag, REPLACE(REPLACE(RankedPosts.Tags, '><', ','), '<', ''), '>') > 0
    GROUP BY 
        Tag
)
SELECT 
    tc.Tag,
    tc.PostCount,
    tc.AvgViews,
    tc.AvgScore,
    MAX(rp.CreationDate) AS MostRecentPostDate
FROM 
    TagCounts tc
LEFT JOIN 
    RankedPosts rp ON EXISTS (
        SELECT 1 
        FROM Posts 
        WHERE Tags LIKE CONCAT('%><', tc.Tag, '>%')
        AND Id = rp.PostId
    )
GROUP BY 
    tc.Tag, tc.PostCount, tc.AvgViews, tc.AvgScore
ORDER BY 
    tc.PostCount DESC, tc.AvgScore DESC
LIMIT 10;
