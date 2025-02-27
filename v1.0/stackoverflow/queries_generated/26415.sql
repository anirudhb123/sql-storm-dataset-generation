WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        P.CreationDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
            PostId 
         FROM 
            Posts) T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1 -- Focus on questions
    GROUP BY 
        P.Id
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 -- Filter users by reputation
), TopQuestions AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.CreationDate,
        PS.Tags,
        RANK() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS Rank
    FROM 
        PostStatistics PS
    WHERE 
        PS.CreationDate > NOW() - INTERVAL '30 days' -- Recent questions
)
SELECT 
    TQ.Title,
    TQ.Score,
    TQ.ViewCount,
    TQ.AnswerCount,
    TQ.CommentCount,
    TQ.Tags,
    U.DisplayName,
    U.Reputation
FROM 
    TopQuestions TQ
JOIN 
    Users U ON TQ.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE 
    TQ.Rank <= 10 -- Get top 10 questions
ORDER BY 
    TQ.Score DESC;
