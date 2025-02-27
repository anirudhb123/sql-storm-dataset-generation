
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
PopularTagStats AS (
    SELECT 
        T.TagName,
        COUNT(RP.PostId) AS PostCount,
        SUM(RP.ViewCount) AS TotalViews,
        AVG(RP.Score) AS AverageScore
    FROM 
        RankedPosts RP
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(RP.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(RP.Tags) - CHAR_LENGTH(REPLACE(RP.Tags, '><', '')) >= numbers.n - 1) T 
    ON 
        RP.TagRank = 1 
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        PopularTagStats
)

SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.AverageScore,
    CASE 
        WHEN TT.Rank <= 5 THEN 'Top Tag'
        WHEN TT.Rank <= 10 THEN 'Popular Tag'
        ELSE 'Emerging Tag'
    END AS TagCategory
FROM 
    TopTags TT
WHERE 
    TT.PostCount > 10 
ORDER BY 
    TT.Rank;
