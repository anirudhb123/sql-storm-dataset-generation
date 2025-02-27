WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High Reputation'
            WHEN U.Reputation >= 500 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    
    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation >= 1000 THEN 'High Reputation'
            WHEN U.Reputation >= 500 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users U
    JOIN 
        UserReputationCTE UR ON U.Id != UR.UserId
    WHERE 
        U.Reputation > UR.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.LastActivityDate,
        P.AcceptedAnswerId,
        U.DisplayName AS OwnerDisplayName,
        PT.Name AS PostType,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.LastActivityDate >= NOW() - INTERVAL '30 days'
),
PostRanked AS (
    SELECT 
        PD.*,
        RANK() OVER (PARTITION BY PD.PostType ORDER BY PD.Score DESC) AS Ranking
    FROM 
        PostDetails PD
)
SELECT 
    PR.PostId,
    PR.Title,
    PR.ViewCount,
    PR.CommentCount,
    PR.Score,
    PR.OwnerDisplayName,
    PR.PostType,
    UR.ReputationCategory
FROM 
    PostRanked PR
LEFT JOIN 
    UserReputationCTE UR ON PR.OwnerDisplayName = UR.DisplayName
WHERE 
    PR.Ranking <= 5
ORDER BY 
    PR.PostType, PR.Score DESC;

-- Add aggregations for votes and badges obtained per user 
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT B.Id) AS BadgeCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
FROM 
    Users U
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    Votes V ON U.Id = V.UserId
GROUP BY 
    U.Id
HAVING 
    COUNT(DISTINCT B.Id) > 0
ORDER BY 
    BadgeCount DESC;

-- Add a full outer join to find users with no posts
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(COUNT(P.Id), 0) AS PostCount
FROM 
    Users U
FULL OUTER JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id
ORDER BY 
    PostCount ASC;
