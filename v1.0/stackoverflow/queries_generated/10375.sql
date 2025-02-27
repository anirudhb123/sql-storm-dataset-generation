-- Performance Benchmark Query
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    UPC.UserId,
    UPC.DisplayName,
    UPC.PostCount,
    UPC.QuestionCount,
    UPC.AnswerCount,
    PVC.VoteCount,
    PVC.UpVoteCount,
    PVC.DownVoteCount
FROM 
    UserPostCounts UPC
LEFT JOIN 
    PostVoteCounts PVC ON UPC.PostCount > 0
ORDER BY 
    UPC.PostCount DESC, PVC.VoteCount DESC;
