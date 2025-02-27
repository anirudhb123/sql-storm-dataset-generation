WITH RecursiveCTE AS (
    -- Recursive CTE to find answers related to questions along with their scores
    SELECT P.Id AS AnswerId, P.Score, 
           P.CreationDate,
           P.OwnerUserId,
           1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 2 -- Answers
    
    UNION ALL
    
    SELECT A.Id, A.Score, A.CreationDate, A.OwnerUserId,
           R.Level + 1
    FROM Posts A
    INNER JOIN Posts Q ON A.ParentId = Q.Id
    INNER JOIN RecursiveCTE R ON Q.AcceptedAnswerId = R.AnswerId
)
SELECT U.DisplayName AS UserName, 
       COUNT(DISTINCT P.Id) AS AnswerCount, 
       COALESCE(SUM(P.Score), 0) AS TotalScore,
       AVG(P.ViewCount) AS AvgViewCount,
       MAX(P.CreationDate) AS LatestAnswerDate,
       MIN(P.CreationDate) AS EarliestAnswerDate,
       STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 2
LEFT JOIN Posts Q ON P.ParentId = Q.Id
LEFT JOIN Tags T ON T.ExcerptPostId = Q.Id
GROUP BY U.Id
HAVING COUNT(DISTINCT P.Id) > 5 -- Only users with more than 5 answers
   AND COALESCE(SUM(P.Score), 0) > 100 -- Total score for answers should be more than 100
ORDER BY TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination for top 10 users

In this query:
- A recursive common table expression (CTE) named RecursiveCTE finds the accepted answers to questions recursively, allowing you to extract necessary details about the relationships between questions and answers.
- The main query aggregates user information, total answers, total scores, average views, and datetime metrics while filtering for users who have answered more than five times and have a score above 100.
- The `STRING_AGG` function is utilized to concatenate tag names associated with the questions related to answers for better visual representation.
- Finally, result pagination is done using `OFFSET ... FETCH NEXT` for performance considerations on the UI side.
