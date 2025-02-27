
WITH TagCounts AS (
    SELECT
        value AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE
        PostTypeId = 1 
    GROUP BY
        value
),
UsersWithBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        u.Id, u.DisplayName
)
SELECT
    uc.DisplayName AS ContributorName,
    uc.QuestionCount,
    uc.TotalScore,
    uc.AcceptedAnswers,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    tc.TagName,
    tc.PostCount
FROM
    TopContributors uc
LEFT JOIN
    UsersWithBadges ub ON uc.UserId = ub.UserId
LEFT JOIN
    TagCounts tc ON tc.PostCount = (
        SELECT MAX(PostCount)
        FROM TagCounts
    )
ORDER BY
    uc.TotalScore DESC, uc.QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
