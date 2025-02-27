
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        P.CreationDate,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
            PostId 
         FROM 
            Posts 
         INNER JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) T ON P.Id = T.PostId
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
        PS.CreationDate > NOW() - INTERVAL 30 DAY 
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
