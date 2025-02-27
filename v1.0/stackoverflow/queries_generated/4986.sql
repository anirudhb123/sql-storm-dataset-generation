WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPosts
    WHERE 
        PostCount > 5
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= (NOW() - INTERVAL '30 days')
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.TotalScore,
    RP.Title AS RecentPostTitle,
    RP.CommentCount
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId 
WHERE 
    RP.RecentPostRank = 1
ORDER BY 
    TU.ScoreRank, TU.DisplayName;

-- Part of the query designed to fetch posts that have higher engagement 
-- by filtering posts with a significant comment count and recent activity.
LEFT JOIN (
    SELECT 
        P.Id,
        FTR.FavoriteCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(DISTINCT Id) AS FavoriteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 5 -- Fetching favorite votes 
        GROUP BY 
            PostId
    ) FTR ON P.Id = FTR.PostId
) PC ON RP.Id = PC.Id
WHERE 
    PC.FavoriteCount IS NOT NULL AND PC.FavoriteCount > 2; 
