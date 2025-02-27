WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        AVG(U.Reputation) AS AvgReputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN P.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.UpVotes,
    RP.DownVotes,
    US.UserId,
    US.AvgReputation,
    US.BadgeCount,
    US.CommentCount,
    US.PostCount
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
JOIN 
    UserStatistics US ON U.Id = US.UserId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
