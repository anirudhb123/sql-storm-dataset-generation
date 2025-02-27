
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
), ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        BadgeCount,
        @ReputationRank := IF(@prevReputation = Reputation, @ReputationRank, @rankRank) AS ReputationRank,
        @prevReputation := Reputation,
        @PostCountRank := IF(@prevPostCount = PostCount, @PostCountRank, @rankPostCount) AS PostCountRank,
        @prevPostCount := PostCount,
        @CommentCountRank := IF(@prevCommentCount = CommentCount, @CommentCountRank, @rankCommentCount) AS CommentCountRank,
        @prevCommentCount := CommentCount
    FROM 
        UserStats, (SELECT @ReputationRank := 0, @PostCountRank := 0, @CommentCountRank := 0, @rankRank := 0, @rankPostCount := 0, @rankCommentCount := 0, @prevReputation := NULL, @prevPostCount := NULL, @prevCommentCount := NULL) AS vars
    ORDER BY Reputation DESC, PostCount DESC, CommentCount DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    BadgeCount,
    ReputationRank,
    PostCountRank,
    CommentCountRank
FROM 
    ActiveUsers
WHERE 
    Reputation > 1000
ORDER BY 
    ReputationRank, PostCountRank, CommentCountRank
LIMIT 10 OFFSET 10;
