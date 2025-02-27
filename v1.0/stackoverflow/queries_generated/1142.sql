WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        COALESCE(PH.RevisionCount, 0) AS RevisionCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS RevisionCount 
         FROM 
            PostHistory 
         GROUP BY 
            PostId) PH ON P.Id = PH.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CreationDate
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        UR.ReputationRank,
        UP.PostCount,
        UP.AnswerCount,
        UP.QuestionCount
    FROM 
        UserReputation UR
    JOIN 
        (SELECT 
            UserId, 
            SUM(PostCount) AS PostCount, 
            SUM(AnswerCount) AS AnswerCount,
            SUM(QuestionCount) AS QuestionCount
         FROM 
            UserReputation
         WHERE 
            ReputationRank <= 10
         GROUP BY 
            UserId) UP ON UR.UserId = UP.UserId
)
SELECT 
    T.DisplayName,
    T.Reputation,
    PP.Title AS PopularPostTitle,
    PP.Score,
    PP.ViewCount,
    PP.AnswerCount,
    PP.CommentCount,
    PP.RevisionCount,
    T.QuestionCount,
    T.AnswerCount
FROM 
    TopUsers T
JOIN 
    PopularPosts PP ON T.AnswerCount > 0 OR T.QuestionCount > 0
ORDER BY 
    T.Reputation DESC, PP.Score DESC
LIMIT 50;
