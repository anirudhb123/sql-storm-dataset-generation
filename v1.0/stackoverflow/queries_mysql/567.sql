
WITH UserStatistics AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.CreationDate AS PostCreationDate,
        U.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_owner = P.OwnerUserId, @row_number + 1, 1) AS OwnerPostRank,
        @prev_owner := P.OwnerUserId
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE 
        P.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
), 
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.ViewCount,
        PD.Score,
        PD.PostCreationDate,
        PD.OwnerDisplayName
    FROM 
        PostDetails PD
    WHERE 
        PD.Score > (SELECT AVG(Score) FROM Posts)
)

SELECT 
    US.Id AS UserID,
    US.DisplayName,
    US.Reputation,
    US.Upvotes,
    US.Downvotes,
    US.PostCount,
    US.CommentCount,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViews,
    PP.Score AS PopularPostScore
FROM 
    UserStatistics US
LEFT JOIN 
    PopularPosts PP ON US.Id = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = PP.PostId)
ORDER BY 
    US.Reputation DESC, US.Upvotes DESC
LIMIT 50;
