WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
), UserRanked AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY PostCount DESC, Upvotes DESC) AS EngagementRank
    FROM 
        UserEngagement
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    Upvotes,
    Downvotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    EngagementRank
FROM 
    UserRanked
WHERE 
    EngagementRank <= 10
ORDER BY 
    EngagementRank;
