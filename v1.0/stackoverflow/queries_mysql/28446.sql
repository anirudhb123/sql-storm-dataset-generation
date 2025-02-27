
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
), 
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        PostCount > 10 
), 
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedQuestions,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TagMetrics AS (
    SELECT 
        tt.Tag, 
        SUM(um.QuestionCount) AS TotalQuestions,
        SUM(um.UpvotedQuestions) AS TotalUpvotes,
        SUM(um.DownvotedQuestions) AS TotalDownvotes,
        COUNT(DISTINCT um.UserId) AS UniqueUsers
    FROM 
        TopTags tt
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tt.Tag, '%')
    JOIN 
        UserMetrics um ON um.QuestionCount > 0 AND p.OwnerUserId = um.UserId
    GROUP BY 
        tt.Tag
)
SELECT 
    tm.Tag,
    tm.TotalQuestions,
    tm.TotalUpvotes,
    tm.TotalDownvotes,
    tm.UniqueUsers,
    tt.PostCount AS TagUsageCount
FROM 
    TagMetrics tm
JOIN 
    TopTags tt ON tm.Tag = tt.Tag
ORDER BY 
    tm.TotalQuestions DESC;
