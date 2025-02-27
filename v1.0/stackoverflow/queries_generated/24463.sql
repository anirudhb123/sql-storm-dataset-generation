WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS TotalPosts,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
CloseCount AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Post Closed and Post Reopened
    GROUP BY 
        PH.PostId
),
ExtendedPostStats AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.CreationDate,
        UC.UserId,
        UC.DisplayName,
        COALESCE(CC.CloseVoteCount, 0) AS CloseVoteCount,
        U.Reputation
    FROM 
        PostInfo PI
    LEFT JOIN 
        UserStats UC ON PI.OwnerUserId = UC.UserId
    LEFT JOIN 
        CloseCount CC ON PI.PostId = CC.PostId
)

SELECT 
    EPS.PostId,
    EPS.Title,
    EPS.CreationDate,
    EPS.DisplayName,
    EPS.CloseVoteCount,
    EPS.Reputation,
    EPS.Reputation * (1 + CAST(EPS.CloseVoteCount AS FLOAT) / NULLIF(DATEDIFF('day', EPS.CreationDate, NOW()) + 1, 0)) AS ScoreImpact,
    CASE 
        WHEN EPS.Reputation < 100 THEN 'Newbie' 
        WHEN EPS.Reputation BETWEEN 100 AND 500 THEN 'Intermediate' 
        ELSE 'Expert' 
    END AS UserLevel
FROM 
    ExtendedPostStats EPS
WHERE 
    EPS.CloseVoteCount > 0
OR 
    (EPS.Reputation IS NOT NULL AND EPS.Reputation > 0)
ORDER BY 
    ScoreImpact DESC, EPS.CreationDate DESC
LIMIT 100;
