
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
        ROW_NUMBER() OVER (PARTITION BY SUBSTR(p.Tags, 2, LEN(p.Tags) - 2) ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01'::date)
),
TagStatistics AS (
    SELECT
        value AS Tag
    FROM 
        RankedPosts,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LEN(Tags) - 2), '><'))
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
        RankedPosts ON RankedPosts.Tags LIKE '%><' || Tag || '>%'
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
        WHERE Tags LIKE '%><' || tc.Tag || '>%'
        AND Id = rp.PostId
    )
GROUP BY 
    tc.Tag, tc.PostCount, tc.AvgViews, tc.AvgScore
ORDER BY 
    tc.PostCount DESC, tc.AvgScore DESC
LIMIT 10;
