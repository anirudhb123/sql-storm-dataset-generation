
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ParsedTags
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
OverallStats AS (
    SELECT 
        COUNT(DISTINCT u.UserId) AS TotalUsers,
        COUNT(DISTINCT ph.PostId) AS TotalClosedPosts,
        AVG(u.Reputation) AS AverageReputation,
        SUM(u.QuestionsCount) AS TotalQuestionsPosted,
        SUM(u.AnswersCount) AS TotalAnswersPosted,
        SUM(u.GoldBadges) AS TotalGoldBadges,
        SUM(u.SilverBadges) AS TotalSilverBadges,
        SUM(u.BronzeBadges) AS TotalBronzeBadges
    FROM 
        UserReputation u
    LEFT JOIN 
        PostHistory ph ON ph.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1 AND ph.PostHistoryTypeId = 10)
)
SELECT
    ts.Tag,
    ts.TagCount,
    os.TotalUsers,
    os.TotalClosedPosts,
    os.AverageReputation,
    os.TotalQuestionsPosted,
    os.TotalAnswersPosted,
    os.TotalGoldBadges,
    os.TotalSilverBadges,
    os.TotalBronzeBadges
FROM 
    TagCounts ts,
    OverallStats os
ORDER BY 
    ts.TagCount DESC, os.AverageReputation DESC
LIMIT 50;
