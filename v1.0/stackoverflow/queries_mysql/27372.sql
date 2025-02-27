
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100  
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  
),
CombinedData AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TotalViews,
        ua.TotalScore,
        pt.Tag
    FROM 
        UserActivity ua
    JOIN 
        PopularTags pt ON ua.TotalPosts > 0  
)
SELECT 
    cd.DisplayName,
    cd.TotalPosts,
    cd.Questions,
    cd.Answers,
    cd.TotalViews,
    cd.TotalScore,
    cd.Tag
FROM 
    CombinedData cd
ORDER BY 
    cd.TotalScore DESC, cd.TotalViews DESC  
LIMIT 50;
