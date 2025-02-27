WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(PH.Edits, 0) AS EditCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName, 
        U.Reputation, 
        UC.UpVotes, 
        UC.DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    JOIN 
        UserVoteCounts UC ON U.Id = UC.UserId
    WHERE 
        UC.PostCount >= 5
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    PA.Title AS PostTitle,
    PA.EditCount,
    PA.CommentCount,
    PA.UpVoteCount,
    PA.DownVoteCount,
    TU.ReputationRank
FROM 
    TopUsers TU
JOIN 
    PostAnalysis PA ON PA.UpVoteCount > PA.DownVoteCount
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, PA.UpVoteCount DESC;
