
WITH TagStats AS (
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
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(c.Score, 0)) AS CommentCount,
        SUM(ISNULL(b.Class, 0)) AS BadgeCount
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
