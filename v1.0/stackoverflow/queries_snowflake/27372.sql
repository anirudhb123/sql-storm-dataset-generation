
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
        SPLIT(p.Tags, '><') AS TagArray
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
TagCounts AS (
    SELECT 
        TRIM(tag) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags,
        LATERAL FLATTEN(INPUT => TagArray) AS tag
    GROUP BY 
        TRIM(tag)
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
        TagCounts pt ON ua.TotalPosts > 0  
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
