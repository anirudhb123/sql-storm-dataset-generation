WITH TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Contributors,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM 
        Tags AS t
    JOIN 
        Posts AS p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditorComments
    FROM 
        PostHistory AS ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        td.TagName,
        td.PostCount,
        td.QuestionCount,
        td.AnswerCount,
        td.Contributors,
        ph.EditCount,
        ph.EditorComments,
        td.Upvotes,
        td.Downvotes
    FROM 
        TagDetails AS td
    LEFT JOIN 
        PostHistoryStats AS ph ON pd.TagName = ANY(STRING_TO_ARRAY((SELECT Tags FROM Posts AS p WHERE p.Id = ph.PostId), ','))
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    Contributors,
    EditCount,
    EditorComments,
    Upvotes,
    Downvotes
FROM 
    FinalResults
ORDER BY 
    PostCount DESC
LIMIT 10;
