-- Performance benchmarking query on Stack Overflow schema
WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Starting with Questions
  
    UNION ALL
  
    SELECT 
        A.Id,
        A.Title,
        A.CreationDate,
        A.Score,
        A.OwnerUserId,
        R.Level + 1
    FROM Posts A
    JOIN RecursiveCTE R ON A.ParentId = R.PostId
    WHERE A.PostTypeId = 2 -- Answers
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    JOIN STRING_TO_ARRAY(P.Tags, ',') AS TagNames ON TRUE
    JOIN Tags T ON T.TagName = TRIM(BOTH '<>' FROM TagNames)  -- Consider < > removal for tags
    GROUP BY P.Id
)
SELECT 
    RCTE.PostId,
    RCTE.Title,
    RCTE.CreationDate,
    COALESCE(PVC.UpVotes, 0) AS UpVotes,
    COALESCE(PVC.DownVotes, 0) AS DownVotes,
    RCTE.Score,
    PT.Tags,
    RCTE.Level
FROM RecursiveCTE RCTE
LEFT JOIN PostVoteCounts PVC ON RCTE.PostId = PVC.PostId
LEFT JOIN PostTags PT ON RCTE.PostId = PT.PostId
WHERE RCTE.Score >= 10  -- Only high-scoring questions
  AND RCTE.CreationDate >= NOW() - INTERVAL '1 year'  -- In the last year
ORDER BY RCTE.Score DESC,
         RCTE.CreationDate DESC;

-- Additional calculations for the user with the highest reputation who posted the most answers
SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(A.Id) AS TotalAnswers
FROM Users U
JOIN Posts A ON U.Id = A.OwnerUserId
WHERE A.PostTypeId = 2 -- Answers
GROUP BY U.Id
ORDER BY U.Reputation DESC
LIMIT 1;

-- Pushing for performance benchmarks by measuring the execution time of above queries when running on large datasets
