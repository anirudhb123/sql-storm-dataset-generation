
WITH RankedQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        COUNT(A.Id) AS AnswerCount,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
        JOIN
            Posts P ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    ) T ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, U.DisplayName
),
FilteredQuestions AS (
    SELECT 
        QuestionId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerName, 
        AnswerCount, 
        Tags,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RankedQuestions
),
MostPopularQuestions AS (
    SELECT 
        QuestionId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerName, 
        AnswerCount, 
        Tags
    FROM 
        FilteredQuestions
    WHERE 
        Rank <= 10
)
SELECT 
    Q.QuestionId,
    Q.Title,
    Q.CreationDate,
    Q.ViewCount,
    Q.Score,
    Q.OwnerName,
    Q.AnswerCount,
    Q.Tags,
    COUNT(C.Id) AS CommentCount
FROM 
    MostPopularQuestions Q
LEFT JOIN 
    Comments C ON C.PostId = Q.QuestionId
GROUP BY 
    Q.QuestionId, Q.Title, Q.CreationDate, Q.ViewCount, Q.Score, Q.OwnerName, Q.AnswerCount, Q.Tags
ORDER BY 
    Q.Score DESC, Q.ViewCount DESC;
