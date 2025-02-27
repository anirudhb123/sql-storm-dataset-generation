WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1) AS QuestionCount,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 2) AS AnswerCount
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 -- Considering users with significant reputation
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        PT.Name AS PostType,
        P.ViewCount,
        P.AnswerCount,
        P.Score,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Tags T ON T.Id IN (SELECT UNNEST(string_to_array(TRIM(BOTH '<>' FROM P.Tags), '> <'))::int)
    GROUP BY 
        P.Id, PT.Name
),
UserPostEngagement AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        PE.PostId,
        PE.PostType,
        PE.ViewCount,
        PE.AnswerCount,
        PE.Score,
        PE.CommentCount,
        PE.Tags
    FROM 
        UserReputation UR
    JOIN 
        Posts P ON P.OwnerUserId = UR.UserId
    JOIN 
        PostEngagement PE ON PE.PostId = P.Id
)
SELECT 
    U.DisplayName AS "User",
    U.Reputation AS "Reputation",
    U.QuestionCount AS "Total Questions",
    U.AnswerCount AS "Total Answers",
    PE.PostType AS "Post Type",
    PE.ViewCount AS "Views",
    PE.AnswerCount AS "Answers",
    PE.CommentCount AS "Comments",
    PE.Score AS "Score",
    PE.Tags AS "Tags"
FROM 
    UserReputation U
JOIN 
    UserPostEngagement PE ON U.UserId = PE.UserId
ORDER BY 
    U.Reputation DESC, PE.ViewCount DESC
LIMIT 
    50; -- Limit to top 50 users based on their engagement
