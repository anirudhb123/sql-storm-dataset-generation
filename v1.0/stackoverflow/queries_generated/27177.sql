WITH Tag_Stats AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY
        t.Id, t.TagName
),
User_Badges AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
Top_Contributors AS (
    SELECT
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS ContributionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS ContributionViews,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only Questions
    GROUP BY
        p.OwnerUserId
)
SELECT
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore,
    ub.UserId,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    tc.ContributionCount,
    tc.ContributionViews
FROM
    Tag_Stats ts
JOIN
    User_Badges ub ON ub.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%<', ts.TagName, '>%'))
JOIN
    Top_Contributors tc ON tc.OwnerUserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%<', ts.TagName, '>%'))
WHERE
    ts.PostCount > 10 -- Tags with more than 10 associated questions
ORDER BY
    ts.TotalViews DESC, tc.ContributionCount DESC;
