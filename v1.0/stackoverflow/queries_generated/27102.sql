WITH TagCTE AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
),
UserCTE AS (
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
    WHERE 
        U.Reputation > 1000 -- Only users with reputation greater than 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        P.CreationDate,
        ARRAY_AGG(DISTINCT TagCTE.Tag) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        TagCTE ON TRUE
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId, P.CreationDate
),
UserPostSummary AS (
    SELECT 
        U.DisplayName,
        P.Title, 
        P.CommentCount,
        P.VoteCount,
        P.CreationDate,
        U.BadgeCount,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.Tags
    FROM 
        PostSummary P
    JOIN 
        UserCTE U ON P.OwnerUserId = U.UserId
)
SELECT 
    DisplayName,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Tags
FROM 
    UserPostSummary
ORDER BY 
    CommentCount DESC, VoteCount DESC
LIMIT 10; -- Limit the result to top 10 questions
