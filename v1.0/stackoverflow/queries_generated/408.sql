WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score IS NOT NULL
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
AnswerStatistics AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalAnswers,
        AVG(Score) AS AvgAnswerScore
    FROM 
        Posts 
    WHERE 
        PostTypeId = 2
    GROUP BY 
        PostId
),
QuestionsWithAnswers AS (
    SELECT 
        TQ.*,
        COALESCE(AS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(AS.AvgAnswerScore, 0) AS AvgAnswerScore
    FROM 
        TopQuestions TQ
    LEFT JOIN 
        AnswerStatistics AS ON TQ.PostId = AS.PostId
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    INNER JOIN 
        Posts P ON PH.PostId = P.Id
    INNER JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    QW.Title,
    QW.CreationDate,
    QW.Score,
    QW.ViewCount,
    QW.TotalAnswers,
    QW.AvgAnswerScore,
    CP.ClosedPostId,
    CP.ClosedDate,
    CP.CloseReason
FROM 
    QuestionsWithAnswers QW
LEFT JOIN 
    ClosedPosts CP ON QW.PostId = CP.ClosedPostId
WHERE 
    QW.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    QW.Score DESC, QW.ViewCount DESC;
