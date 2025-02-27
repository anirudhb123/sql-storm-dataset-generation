
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
            value AS TagName,
            PostId 
         FROM 
            Posts CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS SplitTags) T ON P.Id = T.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.AnswerCount, P.CreationDate
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 
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
        PS.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
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
    TQ.Rank <= 10 
ORDER BY 
    TQ.Score DESC;
