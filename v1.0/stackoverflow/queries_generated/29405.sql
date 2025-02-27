WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgUserReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
),
TopRankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
CombinedStats AS (
    SELECT 
        t.TagName,
        t.PostCount,
        t.QuestionCount,
        t.AnswerCount,
        t.AvgUserReputation,
        u.UserId,
        u.DisplayName,
        u.PostCount AS UserPostCount,
        u.GoldBadges,
        u.SilverBadges,
        u.BronzeBadges,
        u.TotalUpvotes
    FROM 
        TopTags t
    JOIN 
        TopRankedUsers u ON u.PostCount >= t.QuestionCount
)

SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgUserReputation,
    UserId,
    DisplayName,
    UserPostCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalUpvotes
FROM 
    CombinedStats
WHERE 
    TagRank <= 5
ORDER BY 
    PostCount DESC, AvgUserReputation DESC;
