WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(ph.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FinalBenchmark AS (
    SELECT 
        ts.TagName, 
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AvgUserReputation,
        ts.LatestPostDate,
        ua.TotalPosts,
        ua.TotalComments,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        phd.HistoryCount,
        phd.Editors
    FROM 
        TagStatistics ts
    JOIN 
        UserActivity ua ON ts.PostCount > 0
    LEFT JOIN 
        PostHistoryDetails phd ON ts.PostCount = phd.PostId
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgUserReputation,
    LatestPostDate,
    TotalPosts,
    TotalComments,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    HistoryCount,
    Editors
FROM 
    FinalBenchmark
ORDER BY 
    PostCount DESC, AvgUserReputation DESC;
