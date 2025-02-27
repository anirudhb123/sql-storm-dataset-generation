
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS Frequency
    FROM 
        Posts
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
            UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)
),
PopularTags AS (
    SELECT 
        TagName,
        Frequency,
        RANK() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopTagPostCounts AS (
    SELECT
        tf.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        TagFrequency tf
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%', tf.TagName, '%')
    GROUP BY
        tf.TagName
)
SELECT 
    t.TagName,
    tp.PostCount AS TotalPosts,
    pu.DisplayName AS TopUser,
    pu.TotalViews,
    pu.TotalScore
FROM 
    PopularTags t
LEFT JOIN 
    TopTagPostCounts tp ON tp.TagName = t.TagName
LEFT JOIN 
    TopUsers pu ON pu.PostCount = (
        SELECT MAX(PostCount)
        FROM TopUsers
        WHERE UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%', t.TagName, '%'))
    )
WHERE 
    t.TagRank <= 10 
ORDER BY 
    t.Frequency DESC;
