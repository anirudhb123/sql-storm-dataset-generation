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
        u.Reputation > 100  -- Only consider users with reputation greater than 100
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        unnest(string_to_array(p.Tags, '><'))
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Get top 10 tags
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
        PopularTags pt ON ua.TotalPosts > 0  -- Only include users with posts
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
    cd.TotalScore DESC, cd.TotalViews DESC  -- Order by TotalScore and then TotalViews
LIMIT 50;  -- Limit to top 50 entries
