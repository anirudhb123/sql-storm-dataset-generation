
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
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><') 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY  
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
