WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.ViewCount,
        P.OwnerUserId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE -1 END), 0) AS NetVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.ViewCount,
        PD.NetVotes,
        PD.CommentCount,
        RANK() OVER (PARTITION BY PD.OwnerUserId ORDER BY PD.NetVotes DESC, PD.ViewCount DESC) AS PostRank
    FROM 
        PostDetails PD
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.ViewCount AS UserViewCount,
    COALESCE(UBC.TotalBadges, 0) AS UserBadges,
    RP.PostId,
    RP.ViewCount AS PostViewCount,
    RP.NetVotes,
    RP.CommentCount,
    RP.PostRank
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN 
    RankedPosts RP ON U.Id = RP.OwnerUserId
WHERE 
    U.Reputation > 1000
    AND (RP.CommentCount > 0 OR RP.NetVotes > 0)
ORDER BY 
    U.Reputation DESC, 
    RP.PostRank
LIMIT 100;

-- Additional Aggregated Insights for future benchmarking
SELECT 
    PT.Name AS PostType,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    AVG(COALESCE(V.NetVotes, 0)) AS AvgNetVotes,
    SUM(COALESCE(V.TotalComments, 0)) AS TotalComments
FROM 
    PostTypes PT
JOIN 
    Posts P ON PT.Id = P.PostTypeId
LEFT JOIN 
    (SELECT 
         PostId,
         SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
         SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes,
         COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments
     FROM 
         Votes V
     LEFT JOIN 
         Comments C ON V.PostId = C.PostId
     GROUP BY 
         V.PostId) V ON P.Id = V.PostId
GROUP BY 
    PT.Name
HAVING 
    COUNT(DISTINCT P.Id) > 50
ORDER BY 
    TotalPosts DESC;
