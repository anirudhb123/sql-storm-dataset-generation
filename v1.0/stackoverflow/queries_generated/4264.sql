WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        CommentCount,
        BadgeCount,
        ReputationRank
    FROM 
        UserActivity
    WHERE 
        ReputationRank <= 10
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(V.Id), 0) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.CommentCount,
    TU.BadgeCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.VoteCount,
    (PS.UpVotes - PS.DownVotes) AS NetScore,
    CASE 
        WHEN PS.CreationDate < CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'Old'
        ELSE 'New'
    END AS PostAge
FROM 
    TopUsers TU
JOIN 
    PostSummary PS ON TU.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = PS.PostId)
ORDER BY 
    TU.Reputation DESC, 
    NetScore DESC
LIMIT 50;
