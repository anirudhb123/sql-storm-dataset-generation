WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        COALESCE(PA.UserDisplayName, 'No Accepted Answer') AS AcceptedAnswer,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Posts PA ON P.AcceptedAnswerId = PA.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
        AND P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, P.AcceptedAnswerId, PA.UserDisplayName
),
AggregatedPostStats AS (
    SELECT
        U.UserId,
        MAX(UP.Reputation) AS MaxReputation,
        SUM(PS.Score) AS TotalScore,
        COUNT(PS.PostId) AS TotalPosts,
        AVG(PS.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT PS.AcceptedAnswerId) AS TotalAcceptedAnswers
    FROM 
        UserReputation U
    JOIN 
        PostStatistics PS ON U.UserId = PS.OwnerUserId
    GROUP BY 
        U.UserId
)
SELECT 
    A.UserId,
    A.MaxReputation,
    A.TotalScore,
    A.TotalPosts,
    A.AvgViewCount,
    A.TotalAcceptedAnswers,
    RANK() OVER (ORDER BY A.TotalScore DESC) AS ScoreRank,
    CASE 
        WHEN A.TotalAcceptedAnswers = 0 THEN 'No Accepted Answers'
        WHEN A.TotalAcceptedAnswers > 5 THEN 'Highly Active'
        ELSE 'Moderately Active'
    END AS ActivityLevel
FROM 
    AggregatedPostStats A
WHERE 
    A.TotalPosts > 10
ORDER BY 
    A.TotalScore DESC NULLS LAST;
