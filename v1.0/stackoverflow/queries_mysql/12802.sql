
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounty,
        Upvotes,
        Downvotes,
        @PostRank := IF(@prevPostCount = PostCount, @PostRank, @rowNum) AS PostRank,
        @rowNum := @rowNum + 1,
        @prevPostCount := PostCount
    FROM 
        UserStats, (SELECT @rowNum := 1, @PostRank := 0, @prevPostCount := NULL) AS vars
    ORDER BY 
        PostCount DESC
),
TopUsersRanked AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBounty,
        Upvotes,
        Downvotes,
        @UpvoteRank := IF(@prevUpvoteCount = Upvotes, @UpvoteRank, @rowNum) AS UpvoteRank,
        @rowNum := @rowNum + 1,
        @prevUpvoteCount := Upvotes
    FROM 
        TopUsers, (SELECT @rowNum := 1, @UpvoteRank := 0, @prevUpvoteCount := NULL) AS vars
    ORDER BY 
        Upvotes DESC
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    QuestionCount,
    TotalBounty,
    Upvotes,
    Downvotes,
    PostRank,
    UpvoteRank
FROM 
    TopUsersRanked
WHERE 
    PostRank <= 10 OR UpvoteRank <= 10
ORDER BY 
    PostRank, UpvoteRank;
