WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),

PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(PH.CreationDate, '1970-01-01') AS LastEdited,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
            ELSE 'Unanswered' 
        END AS PostStatus
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.CommentCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.LastEdited,
    PS.PostStatus
FROM UserActivity UA
JOIN PostStats PS ON UA.UserId = PS.Id
ORDER BY UA.PostCount DESC, UA.UpVotes DESC;
