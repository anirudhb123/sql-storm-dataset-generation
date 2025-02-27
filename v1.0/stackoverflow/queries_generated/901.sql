WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN C.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveComments,
        COALESCE(SUM(CASE WHEN C.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeComments
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        ROW_NUMBER() OVER (ORDER BY UR.Reputation DESC) AS Ranking
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > 1000
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC, PD.ViewCount DESC) AS PostRank
    FROM 
        PostDetails PD
)
SELECT 
    TU.DisplayName,
    TU.Ranking,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.CommentCount,
    RP.PositiveComments,
    RP.NegativeComments
FROM 
    TopUsers TU
JOIN 
    RankedPosts RP ON TU.UserId = RP.PostId
WHERE 
    RP.PostRank <= 10
    AND RP.ViewCount > 100
ORDER BY 
    TU.Ranking, RP.Score DESC;
