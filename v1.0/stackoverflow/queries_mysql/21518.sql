
WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN P.Id END) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        (SELECT COUNT(1) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(1) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        @rownum := IF(@prevOwnerUserId = P.OwnerUserId, @rownum + 1, 1) AS PostRank,
        @prevOwnerUserId := P.OwnerUserId
    FROM 
        Posts P,
        (SELECT @rownum := 0, @prevOwnerUserId := -1) AS r
    WHERE 
        P.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR)
    ORDER BY 
        P.OwnerUserId, P.LastActivityDate DESC
),
UserPostDetails AS (
    SELECT 
        US.UserId,
        US.Reputation,
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.CommentCount,
        PS.UpVoteCount,
        PS.DownVoteCount
    FROM 
        UserScores US
    JOIN 
        PostSummary PS ON US.UserId = PS.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    UPS.PostId,
    UPS.Title,
    UPS.ViewCount,
    UPS.CommentCount,
    UPS.UpVoteCount,
    UPS.DownVoteCount,
    CASE 
        WHEN UPS.UpVoteCount > UPS.DownVoteCount THEN 'Positive'
        WHEN UPS.UpVoteCount < UPS.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
FROM 
    Users U
LEFT JOIN 
    UserPostDetails UPS ON U.Id = UPS.UserId
WHERE 
    (UPS.CommentCount > 0 OR UPS.ViewCount > 100)
    AND (UPS.Reputation IS NOT NULL OR U.Reputation > 0)
ORDER BY 
    VoteSentiment DESC, U.Reputation DESC
LIMIT 100;
