WITH UserAggregates AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY UA.Reputation DESC, UA.PostCount DESC, UA.CommentCount DESC) AS UserRank
    FROM 
        UserAggregates UA
)
SELECT 
    RU.UserId,
    RU.DisplayName,
    RU.Reputation,
    RU.PostCount,
    RU.CommentCount,
    RU.UpVoteCount,
    RU.DownVoteCount,
    RU.BadgeCount,
    RU.UserRank
FROM 
    RankedUsers RU
WHERE 
    RU.UserRank <= 10
ORDER BY 
    RU.UserRank;
