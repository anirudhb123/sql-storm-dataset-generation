
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        AVG(p.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS TopContributors
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        PositiveScoreCount,
        NegativeScoreCount,
        AverageScore,
        TopContributors,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    WHERE 
        PostCount > 5
    ORDER BY 
        PostCount DESC
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.PositiveScoreCount,
    pt.NegativeScoreCount,
    pt.AverageScore,
    pt.TopContributors,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%<', pt.TagName, '>%'))) AS TotalVotes
FROM 
    PopularTags pt
WHERE 
    pt.Rank <= 10
ORDER BY 
    pt.Rank;
