
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        AVG(IFNULL(p.ViewCount, 0)) AS AvgViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    JOIN 
    (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 10
),
TopUsers AS (
    SELECT 
        ws.UserId,
        ws.DisplayName,
        ws.TotalPosts,
        ws.Questions,
        ws.Answers,
        ws.TotalScore,
        ws.AvgViews,
        pt.TagName,
        @rank := IF(@prev_tag = pt.TagName, @rank + 1, 1) AS Rank,
        @prev_tag := pt.TagName
    FROM 
        UserPostStats ws
    JOIN 
        PopularTags pt ON ws.UserId IN (
            SELECT 
                u.Id
            FROM 
                Users u
            JOIN 
                Posts p ON u.Id = p.OwnerUserId
            WHERE 
                p.Tags LIKE CONCAT('%', pt.TagName, '%')
        ),
        (SELECT @rank := 0, @prev_tag := '') AS r
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalScore,
    tu.AvgViews,
    tu.TagName
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 5
ORDER BY 
    tu.TagName, tu.TotalScore DESC;
