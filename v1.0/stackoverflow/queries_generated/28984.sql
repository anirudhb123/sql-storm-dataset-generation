WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS ContributionCount,
        AVG(u.Reputation) AS AverageReputation,
        SUM(COALESCE(b.Class = 1, 0)) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
QuestionDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        ps.QuestionCount,
        ps.AnswerCount,
        COALESCE(ps.PostCount, 0) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        TagStats ps ON ps.TagName = ANY (TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))))
    WHERE 
        p.PostTypeId = 1 
)
SELECT 
    q.PostId,
    q.Title,
    q.OwnerName,
    q.CreationDate,
    q.QuestionCount,
    q.AnswerCount,
    q.TagCount,
    u.AverageReputation AS OwnerAverageReputation,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM 
    QuestionDetails q
JOIN 
    UserReputation u ON q.OwnerUserId = u.UserId
WHERE 
    q.Rn <= 5 -- Top 5 questions per user
ORDER BY 
    q.CreationDate DESC;
