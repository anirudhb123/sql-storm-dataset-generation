WITH ProcessedTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        STRING_AGG(T.TagName, ', ') AS FormattedTags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        (SELECT 
            Id, 
            UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))::varchar) AS TagName 
         FROM 
            Posts) T ON T.Id = P.Id
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        P.Id, P.Title, P.ViewCount, U.DisplayName, U.Reputation
),
AnswerStatistics AS (
    SELECT 
        P.ParentId AS QuestionId,
        COUNT(*) AS AnswerCount,
        COALESCE(AVG(P.Score), 0) AS AverageScore,
        COALESCE(MAX(P.CreationDate), '1970-01-01') AS LastAnswerDate
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2 -- Only Answers
    GROUP BY 
        P.ParentId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    PT.PostId,
    PT.Title,
    PT.ViewCount,
    PT.FormattedTags,
    PT.OwnerDisplayName,
    PT.OwnerReputation,
    AS.AnswerCount,
    AS.AverageScore,
    AS.LastAnswerDate,
    CP.ClosedDate,
    CP.CloseReason
FROM 
    ProcessedTags PT
LEFT JOIN 
    AnswerStatistics AS ON PT.PostId = AS.QuestionId
LEFT JOIN 
    ClosedPosts CP ON PT.PostId = CP.PostId
ORDER BY 
    PT.ViewCount DESC, 
    AS.AverageScore DESC NULLS LAST
LIMIT 100;
