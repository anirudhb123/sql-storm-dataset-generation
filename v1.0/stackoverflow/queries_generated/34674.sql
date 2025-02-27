WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all answers to each question
    SELECT 
        P.Id AS QuestionId,
        P.Title AS QuestionTitle,
        A.Id AS AnswerId,
        A.Title AS AnswerTitle,
        0 AS Level
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        PH.QuestionId,
        PH.QuestionTitle,
        A.Id AS AnswerId,
        A.Title AS AnswerTitle,
        Level + 1
    FROM 
        RecursivePostHierarchy PH
    INNER JOIN 
        Posts A ON PH.AnswerId = A.ParentId
)

SELECT 
    Q.QuestionId,
    Q.QuestionTitle,
    COUNT(A.AnswerId) AS TotalAnswers,
    AVG(CASE 
            WHEN COALESCE(V.Score, 0) > 0 THEN 1 
            ELSE 0 
        END) * 100 AS PercentAcceptedAnswers,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM STRING_TO_ARRAY(Q.Tags, ', ') AS TagNames 
     JOIN Tags T ON T.TagName = TRIM(BOTH '<>' FROM TagNames)) AS Tags
FROM 
    RecursivePostHierarchy Q
LEFT JOIN 
    Posts A ON Q.AnswerId = A.Id
LEFT JOIN 
    Votes V ON A.Id = V.PostId
LEFT JOIN 
    Comments C ON A.Id = C.PostId
WHERE 
    A.PostTypeId = 2 -- Only Answers
GROUP BY 
    Q.QuestionId, 
    Q.QuestionTitle
HAVING 
    COUNT(A.AnswerId) > 0 -- Only questions with answers
ORDER BY 
    TotalUpvotes DESC, 
    QuestionTitle
LIMIT 10;

This SQL query achieves the following:
- Uses a Recursive Common Table Expression (CTE) to construct a hierarchy that relates questions to their answers.
- Counts total answers per question and calculates the percentage of accepted answers.
- Aggregates votes into counts for upvotes and downvotes.
- Includes a derived column that concatenates all unique tags for each question.
- Filters out questions without answers and limits the results to the top ten questions sorted by upvotes.
