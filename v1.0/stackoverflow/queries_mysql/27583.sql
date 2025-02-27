
WITH TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 
        UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15 
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS CommentCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.TotalScore,
        ua.CommentCount,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.TotalScore DESC, ua.QuestionCount DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.QuestionCount > 0
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM 
        TagStats ts
    WHERE 
        ts.PostCount > 1
)
SELECT 
    t.TagName,
    t.PostCount,
    COALESCE(u.DisplayName, 'No Contributor') AS Contributor,
    COALESCE(u.QuestionCount, 0) AS UserQuestions,
    COALESCE(u.TotalScore, 0) AS UserScore,
    COALESCE(u.CommentCount, 0) AS UserComments,
    COALESCE(u.BadgeCount, 0) AS UserBadges
FROM 
    TopTags t
LEFT JOIN 
    TopUsers u ON u.Rank = 1 
WHERE 
    t.TagRank <= 10 
ORDER BY 
    t.PostCount DESC;
