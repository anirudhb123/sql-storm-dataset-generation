
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostScoreRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        @rownum := @rownum + 1 AS ScoreRank
    FROM 
        Posts P, (SELECT @rownum := 0) r
    WHERE 
        P.PostTypeId = 1  
    ORDER BY 
        P.Score DESC
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        @recentRank := IF(@prevPostId = PH.PostId, @recentRank + 1, 1) AS RecentChangeRank,
        @prevPostId := PH.PostId
    FROM 
        PostHistory PH, (SELECT @recentRank := 0, @prevPostId := NULL) r
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        PH.PostId, PH.CreationDate DESC
),
ActivePostLinks AS (
    SELECT 
        PL.PostId,
        PL.RelatedPostId,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks PL
    INNER JOIN 
        Posts P ON PL.PostId = P.Id
    WHERE 
        P.LastActivityDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        PL.PostId, PL.RelatedPostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UVS.TotalVotes,
    UVS.Upvotes,
    UVS.Downvotes,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ScoreRank,
    RP.RecentChangeRank,
    COALESCE(AL.LinkCount, 0) AS ActiveLinks
FROM 
    Users U
INNER JOIN 
    UserVoteStats UVS ON U.Id = UVS.UserId
INNER JOIN 
    PostScoreRanked PS ON U.Id = PS.PostId  
LEFT JOIN 
    RecentPostHistory RP ON PS.PostId = RP.PostId AND RP.RecentChangeRank = 1
LEFT JOIN 
    ActivePostLinks AL ON PS.PostId = AL.PostId
WHERE 
    U.Reputation >= 1000  
    AND PS.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)  
ORDER BY 
    U.Reputation DESC, PS.Score DESC;
