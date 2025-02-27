
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS PostsCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        PostsCount,
        @rank := IF(@prevReputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prevReputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prevReputation := NULL) r
    WHERE 
        PostsCount > 10
    ORDER BY 
        Reputation DESC
), 
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
), 
PostComments AS (
    SELECT 
        C.PostId,
        C.UserId,
        C.Text,
        @commentRank := IF(@prevPostId = C.PostId, @commentRank + 1, 1) AS CommentRank,
        @prevPostId := C.PostId
    FROM 
        Comments C, (SELECT @commentRank := 0, @prevPostId := NULL) r
    ORDER BY 
        C.PostId, C.CreationDate DESC
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalBounty,
    T.TagName,
    PC.Text AS RecentComment,
    PC.CommentRank
FROM 
    TopUsers U
LEFT JOIN 
    PopularTags T ON T.TagCount > 10
LEFT JOIN 
    PostComments PC ON U.UserId = PC.UserId AND PC.CommentRank = 1
WHERE 
    U.ReputationRank <= 20
ORDER BY 
    U.Reputation DESC, U.DisplayName ASC
LIMIT 50;
