WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%<' || T.TagName || '>%' -- Assuming tags are formatted with angle brackets
    WHERE 
        P.PostTypeId = 1 -- Only questions
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS HistoryActionCount,
        STRING_AGG(PHT.Name, '; ') AS ActionNames
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    U.DisplayName AS UserName,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PP.Title AS PopularPostTitle,
    PP.Score AS PopularPostScore,
    PP.ViewCount AS PopularPostViewCount,
    PP.AnswerCount AS PopularPostAnswerCount,
    PP.CommentCount AS PopularPostCommentCount,
    PP.TagsList AS PopularPostTags,
    PHS.HistoryActionCount AS PostHistoryCount,
    PHS.ActionNames AS HistoryActions
FROM 
    UserBadges U
CROSS JOIN 
    PopularPosts PP
LEFT JOIN 
    PostHistorySummary PHS ON PP.PostId = PHS.PostId
ORDER BY 
    U.BadgeCount DESC, PP.Score DESC;
