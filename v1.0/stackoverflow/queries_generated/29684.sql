WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM
        Tags AS tag
    JOIN
        Posts AS p ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%')
    GROUP BY
        tag.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS RankByTotalViews,
        ROW_NUMBER() OVER (ORDER BY AverageScore DESC) AS RankByAverageScore
    FROM
        TagCounts
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        COUNT(c.Id) AS TotalComments,
        COUNT(b.Id) AS TotalBadges
    FROM
        Users AS u
    LEFT JOIN
        Votes AS v ON v.UserId = u.Id
    LEFT JOIN
        Comments AS c ON c.UserId = u.Id
    LEFT JOIN
        Badges AS b ON b.UserId = u.Id
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id
),
UserEngagement AS (
    SELECT
        ua.UserId,
        ua.DisplayName,
        SUM(tc.PostCount) AS ParticipatedTags,
        SUM(tc.TotalViews) AS ViewsFromParticipatedTags,
        SUM(tc.AverageScore) AS AverageScoreFromParticipatedTags
    FROM
        UserActivity AS ua
    JOIN
        Posts AS p ON p.OwnerUserId = ua.UserId
    JOIN
        Tags AS t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    JOIN
        TagCounts AS tc ON t.TagName = tc.TagName
    GROUP BY
        ua.UserId, ua.DisplayName
)
SELECT
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.AverageScore,
    ue.UserId,
    ue.DisplayName,
    ue.ParticipatedTags,
    ue.ViewsFromParticipatedTags,
    ue.AverageScoreFromParticipatedTags
FROM
    TopTags AS tt
JOIN
    UserEngagement AS ue ON ue.ParticipatedTags > 0
WHERE
    tt.RankByPostCount <= 10 OR 
    tt.RankByTotalViews <= 10 OR 
    tt.RankByAverageScore <= 10
ORDER BY
    tt.PostCount DESC, 
    ue.TotalVotes DESC;
