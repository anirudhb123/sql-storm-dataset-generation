WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),
PostStats AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.OwnerUserId
),
UserPostStats AS (
    SELECT
        U.UserId,
        U.DisplayName,
        U.Reputation,
        PS.PostCount,
        PS.TotalScore,
        PS.CommentCount,
        COALESCE(B.BadgeCount, 0) AS BadgeCount
    FROM
        UserReputation U
    LEFT JOIN
        PostStats PS ON U.UserId = PS.OwnerUserId
    LEFT JOIN (
        SELECT
            UserId,
            COUNT(Id) AS BadgeCount
        FROM
            Badges
        GROUP BY
            UserId
    ) B ON U.UserId = B.UserId
)
SELECT
    UPS.UserId,
    UPS.DisplayName,
    UPS.Reputation,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.CommentCount,
    UPS.BadgeCount,
    (SELECT ARRAY_AGG(DISTINCT T.TagName)
     FROM Tags T 
     JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
     WHERE P.OwnerUserId = UPS.UserId) AS Tags,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.UserId = UPS.UserId 
     AND V.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.UserId = UPS.UserId 
     AND V.VoteTypeId = 3) AS Downvotes
FROM
    UserPostStats UPS
WHERE
    UPS.ReputationRank <= 10
ORDER BY
    UPS.Reputation DESC
LIMIT 10;
