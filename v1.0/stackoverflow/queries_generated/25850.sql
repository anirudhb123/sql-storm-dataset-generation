WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Filter for questions
),
PopularTagPosts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        p.Score
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Filter for questions
),
AggregatedTagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        PopularTagPosts
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgScore,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS TagRank 
    FROM 
        AggregatedTagStats
    WHERE 
        PostCount > 5 -- Select tags with more than 5 associated posts
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Filter for questions
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 10 -- At least 10 questions asked
)
SELECT 
    t.TagName,
    t.PostCount,
    t.AvgScore,
    t.TotalViews,
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.TotalScore,
    u.AvgScore
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.QuestionCount = (SELECT MAX(QuestionCount) FROM TopUsers)
ORDER BY 
    t.TotalViews DESC, 
    u.TotalScore DESC;
