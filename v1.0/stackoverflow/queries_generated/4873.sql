WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT PS.PostId) AS TotalPosts,
        SUM(PS.CommentCount) AS TotalComments,
        SUM(PS.UpVotes) AS TotalUpVotes,
        SUM(PS.DownVotes) AS TotalDownVotes
    FROM 
        RankedUsers U
    LEFT JOIN 
        PostSummary PS ON U.UserId = PS.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UE.UserId,
    UE.DisplayName,
    UE.TotalPosts,
    UE.TotalComments,
    UE.TotalUpVotes,
    UE.TotalDownVotes,
    CASE 
        WHEN UE.TotalPosts IS NOT NULL THEN 
            ROUND((UE.TotalUpVotes::FLOAT / NULLIF(UE.TotalComments, 0)) * 100, 2)
        ELSE 
            0 
    END AS EngagementRate,
    COALESCE(B.Name, 'No Badge') AS BadgeName
FROM 
    UserEngagement UE
LEFT JOIN 
    Badges B ON UE.UserId = B.UserId AND B.Class = 1 -- Gold badges
WHERE 
    UE.TotalPosts > 10
ORDER BY 
    UE.TotalUpVotes DESC
FETCH FIRST 10 ROWS ONLY;
