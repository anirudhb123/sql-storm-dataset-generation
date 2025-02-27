-- Performance benchmarking query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalBounty,
    U.UpVoteCount AS UserUpVotes,
    U.DownVoteCount AS UserDownVotes,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.ViewCount AS PostViews,
    P.Score AS PostScore,
    P.CommentCount AS PostComments,
    P.UpVoteCount AS PostUpVotes,
    P.DownVoteCount AS PostDownVotes
FROM 
    UserStats U
JOIN 
    PostEngagement P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
