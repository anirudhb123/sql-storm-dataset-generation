WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= DATEADD(year, -1, GETDATE()) -- Filter for posts created in the last year
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM
        RankedPosts
    WHERE
        PostRank = 1 AND PostTypeId = 1 -- Top question per PostTypeId
),
TopAnswers AS (
    SELECT 
        PostId,
        ParentId,
        Score,
        ViewCount,
        OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ParentId ORDER BY Score DESC) AS AnswerRank
    FROM
        Posts
    WHERE
        PostTypeId = 2 -- Answers
),
AcceptedAnswers AS (
    SELECT 
        P.Id AS AnswerId,
        P.ParentId,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 2 AND P.Id IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
),
CommentsPerPost AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM
        Comments C
    GROUP BY
        C.PostId
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM
        PostHistory
    WHERE
        PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Title/Body/Tags edits and closures
    GROUP BY 
        PostId
)
SELECT 
    Q.Title AS QuestionTitle,
    Q.Score AS QuestionScore,
    Q.ViewCount AS QuestionViewCount,
    Q.OwnerDisplayName AS QuestionOwner,
    COALESCE(A.AnswerCount, 0) AS AnswerCount,
    COALESCE(H.EditCount, 0) AS EditCount,
    COALESCE(C.CommentCount, 0) AS CommentCount
FROM 
    TopQuestions Q
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount FROM TopAnswers WHERE AnswerRank = 1 GROUP BY ParentId) A ON Q.PostId = A.ParentId
LEFT JOIN 
    CommentsPerPost C ON Q.PostId = C.PostId
LEFT JOIN 
    PostHistoryStats H ON Q.PostId = H.PostId
ORDER BY 
    Q.Score DESC, Q.ViewCount DESC
OPTION (RECOMPILE); -- For performance benchmarking

-- Additional statistics if needed, such as user reputation of question owners and the type of edits made.
