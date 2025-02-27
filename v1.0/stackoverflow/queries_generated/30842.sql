WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.LastAccessDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.LastAccessDate,
        UR.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputation UR ON U.Reputation > UR.Reputation
    WHERE 
        UR.Level < 5
),

TopUsers AS (
    SELECT
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 5000
),

PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
),

PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COALESCE(CW.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        PostsWithComments CW ON P.Id = CW.PostId
    WHERE 
        P.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
)

SELECT 
    U.DisplayName,
    U.Reputation,
    Pu.PostId,
    Pu.Title,
    Pu.ViewCount,
    Pu.Score,
    Pu.CommentCount
FROM 
    TopUsers U
JOIN 
    PopularPosts Pu ON U.Id = Pu.OwnerUserId
WHERE 
    EXISTS (SELECT 1 FROM Votes V WHERE V.PostId = Pu.PostId AND V.UserId = U.Id AND V.VoteTypeId = 2) -- Upvotes
ORDER BY 
    U.Reputation DESC,
    Pu.ViewCount DESC
LIMIT 10;

This query makes use of CTEs to establish a hierarchy of user reputations, identify top users, and find popular posts that are actively discussed. The final selection combines this data to show top users who have upvoted popular posts, providing insights into the engagement of notable contributors within the community.
