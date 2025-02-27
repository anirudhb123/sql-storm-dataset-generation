WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
FinalStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.VoteCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.AverageScore,
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostsCount,
        UR.GoldBadges,
        UR.SilverBadges,
        UR.BronzeBadges
    FROM 
        PostStatistics PS
    JOIN 
        Users UR ON UR.Id = (SELECT OwnerUserId FROM Posts WHERE Id = PS.PostId)
)
SELECT 
    FS.*,
    ROW_NUMBER() OVER (ORDER BY FS.AverageScore DESC, FS.VoteCount DESC) AS Rank
FROM 
    FinalStats FS
ORDER BY 
    FS.Rank
LIMIT 100;
