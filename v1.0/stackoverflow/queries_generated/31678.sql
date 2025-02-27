WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
FilteredStats AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalBadges,
        Rank
    FROM UserPostStats
    WHERE PostCount > 5
),
UserAverageScore AS (
    SELECT 
        UserId,
        AVG(TotalScore) AS AvgScore
    FROM FilteredStats
    GROUP BY UserId
)
SELECT 
    fs.DisplayName,
    fs.PostCount,
    fs.TotalScore,
    fs.TotalBadges,
    uas.AvgScore,
    CASE 
        WHEN fs.TotalScore > uas.AvgScore THEN 'Above Average'
        WHEN fs.TotalScore < uas.AvgScore THEN 'Below Average'
        ELSE 'Average'
    END AS ScoreComparison
FROM FilteredStats fs
JOIN UserAverageScore uas ON fs.UserId = uas.UserId
ORDER BY fs.PostCount DESC, fs.TotalScore DESC;

-- Additional markers on the total number of distinct tags
SELECT 
    u.DisplayName, 
    COUNT(DISTINCT t.TagName) AS DistinctTagsCount
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag_array ON TRUE
JOIN Tags t ON t.TagName = tag_array::varchar
GROUP BY u.DisplayName;

This SQL code provides a performance benchmark by computing various statistics about users with a minimum number of posts. It utilizes recursive common table expressions (CTEs) to aggregate data, along with window functions for ranking users. The query includes a scoring system where users are compared against their average score within the filtered group and additionally calculates distinct tag counts for each user based on their associated posts.
