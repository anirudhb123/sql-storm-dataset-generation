WITH TagCounts AS (
    SELECT 
        TagName,
        COUNT(PostId) AS PostCount
    FROM 
        Tags
    INNER JOIN 
        Posts ON Tags.Id = Posts.Tags::varchar[] -- Assuming Tags is an array of tag IDs, using array join
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
TopQuestions AS (
    SELECT 
        Id AS QuestionId,
        Title,
        ViewCount,
        Score
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    AND 
        Tags LIKE '%' || (SELECT STRING_AGG(TagName, '%') FROM TopTags) || '%' -- Filter by top tags
    ORDER BY 
        Score DESC 
    LIMIT 5
),
QuestionComments AS (
    SELECT 
        Q.QuestionId,
        C.Text AS CommentText,
        C.CreationDate AS CommentDate,
        U.DisplayName AS CommenterName
    FROM 
        TopQuestions Q
    LEFT JOIN 
        Comments C ON Q.QuestionId = C.PostId
    LEFT JOIN 
        Users U ON C.UserId = U.Id
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS EditDate,
        P.Title AS EditedPostTitle,
        P.ViewCount,
        PH.Comment AS ModificationReason,
        P.Body
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
)
SELECT 
    Q.QuestionId,
    Q.Title,
    Q.ViewCount,
    Q.Score,
    COALESCE(STRING_AGG(DISTINCT CC.CommentText, '; '), 'No comments') AS AllComments,
    PH.EditDate,
    PH.EditedPostTitle,
    PH.ModificationReason
FROM 
    TopQuestions Q
LEFT JOIN 
    QuestionComments CC ON Q.QuestionId = CC.QuestionId
LEFT JOIN 
    PostHistoryData PH ON Q.QuestionId = PH.PostId
GROUP BY 
    Q.QuestionId, Q.Title, Q.ViewCount, Q.Score, PH.EditDate, PH.EditedPostTitle, 
    PH.ModificationReason
ORDER BY 
    Q.Score DESC;
