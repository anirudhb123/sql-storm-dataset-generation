WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only for questions
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only for questions
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.Tag,
        COUNT(pt.PostId) AS PostCount,
        SUM(us.TotalViews) AS TotalViews,
        AVG(us.TotalScore) AS AvgScore
    FROM 
        PostTags pt
    JOIN 
        Tags t ON pt.Tag = t.TagName
    JOIN 
        UserStats us ON us.QuestionCount > 0 
    GROUP BY 
        t.Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    Tag,
    PostCount,
    TotalViews,
    AvgScore
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;

This SQL query first creates common table expressions (CTEs) to extract tag data from posts, user statistics related to questions, and aggregate tag statistics. Finally, it retrieves the top 10 tags by total views along with their associated post counts and average scores for benchmarking purposes.
