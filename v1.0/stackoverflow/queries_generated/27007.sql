WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))::text) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(pt.TagCount) AS AvgTagsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTagCounts pt ON p.Id = pt.PostId
    GROUP BY 
        u.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        AvgTagsPerPost,
        RANK() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    Rank,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    AvgTagsPerPost
FROM 
    RankedUsers
WHERE 
    Rank <= 10 -- Top 10 users by total score
ORDER BY 
    Rank;
