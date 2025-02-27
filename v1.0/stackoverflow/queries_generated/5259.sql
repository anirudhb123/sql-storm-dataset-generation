WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),
MostActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.Questions,
        us.Answers,
        us.TotalScore,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 10
)
SELECT 
    mu.UserId,
    mu.DisplayName,
    mu.TotalPosts,
    mu.Questions,
    mu.Answers,
    mu.TotalScore,
    tt.TagName,
    tt.TotalViews,
    tt.PostCount
FROM 
    MostActiveUsers mu
JOIN 
    TopTags tt ON tt.PostCount > 0
ORDER BY 
    mu.TotalScore DESC, 
    tt.TotalViews DESC;
