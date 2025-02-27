WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY (string_to_array(Posts.Tags, ',')::int[])
    GROUP BY 
        Tags.TagName
),

BadgeStats AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(Badges.Id) AS BadgeCount,
        SUM(CASE WHEN Badges.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Badges.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Badges.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId
    GROUP BY 
        Users.Id
),

PostHistorySummary AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosed,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN CreationDate END) AS LastReopened,
        COUNT(CASE WHEN PostHistoryTypeId = 24 THEN 1 END) AS EditCount,
        COUNT(CASE WHEN PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.TotalScore,
    U.UserId,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PHS.LastClosed,
    PHS.LastReopened,
    PHS.EditCount,
    PHS.DeleteCount
FROM 
    TagStats T
JOIN 
    Users U ON U.Reputation > 1000  -- Only users with reputation greater than 1000
LEFT JOIN 
    PostHistorySummary PHS ON PHS.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || T.TagName || '%')
ORDER BY 
    T.TotalViews DESC, U.BadgeCount DESC
LIMIT 50;
