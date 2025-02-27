WITH RECURSIVE TopTags AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        Tags.Count,
        1 AS Level
    FROM 
        Tags
    WHERE 
        Tags.Count > 100  -- Threshold for top tags
    UNION ALL
    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        TT.Level + 1
    FROM 
        Tags T
    JOIN 
        TopTags TT ON T.Count < TT.Count AND T.TagName != TT.TagName 
    WHERE 
        TT.Level < 5  -- Limit the recursive depth
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE 
                WHEN P.PostTypeId = 1 THEN P.Score 
                ELSE 0 
            END) AS QuestionScore,
        SUM(CASE 
                WHEN P.PostTypeId = 2 THEN P.Score 
                ELSE 0 
            END) AS AnswerScore,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        U.Reputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostActivity AS (
    SELECT 
        P.Id,
        P.OwnerUserId,
        COUNT(C) AS CommentCount,
        COUNT(V) AS VoteCount,
        MAX(PH.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
FinalReport AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(BG.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
        UR.Reputation,
        UR.TotalPosts,
        UR.QuestionScore,
        UR.AnswerScore,
        PA.CommentCount,
        PA.VoteCount,
        PA.LastActivity
    FROM 
        Users U
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN 
        BadgeStats BG ON U.Id = BG.UserId
    LEFT JOIN 
        PostActivity PA ON U.Id = PA.OwnerUserId
)
SELECT 
    FR.UserId,
    FR.DisplayName,
    FR.GoldBadges,
    FR.SilverBadges,
    FR.BronzeBadges,
    FR.Reputation,
    FR.TotalPosts,
    FR.QuestionScore,
    FR.AnswerScore,
    FR.CommentCount,
    FR.VoteCount,
    FR.LastActivity,
    T.TagName,
    T.Count
FROM 
    FinalReport FR
LEFT JOIN 
    TopTags T ON FR.QuestionScore >= (SELECT AVG(QuestionScore) FROM FinalReport)
ORDER BY 
    FR.Reputation DESC, FR.TotalPosts DESC;
