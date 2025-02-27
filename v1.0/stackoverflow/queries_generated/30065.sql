WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Select only questions

    UNION ALL

    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        Posts PA ON P.ParentId = PA.Id  -- Join to find answers to the questions
    WHERE 
        PA.PostTypeId = 1
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS QuestionCount,
    COUNT(DISTINCT A.Id) AS AnswerCount,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
    SUM(CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 1 
            ELSE 0 
        END) AS ClosedPostCount,
    MAX(PH.CreationDate) AS LastClosedPostDate,
    ARRAY_AGG(DISTINCT T.TagName) AS Tags
FROM 
    Users U
LEFT JOIN 
    Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1
LEFT JOIN 
    Posts A ON A.ParentId = P.Id  -- Linking answers to the questions
LEFT JOIN 
    Votes V ON V.PostId = P.Id
LEFT JOIN 
    PostHistory PH ON PH.PostId = P.Id
LEFT JOIN 
    Tags T ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])  -- Extracting tags from the question
WHERE 
    U.Reputation > 1000  -- Filtering users by reputation
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT A.Id) > 5  -- Users must have more than 5 answers
ORDER BY 
    U.Reputation DESC, QuestionCount DESC;

-- An additional separate query to benchmark performance of duplicated answer counts
WITH AnswerCounts AS (
    SELECT 
        ParentId,
        COUNT(*) AS TotalAnswers
    FROM 
        Posts
    WHERE 
        PostTypeId = 2  -- Answers
    GROUP BY 
        ParentId
)

SELECT 
    P.Id AS QuestionId,
    P.Title,
    AC.TotalAnswers
FROM 
    Posts P
LEFT JOIN 
    AnswerCounts AC ON P.Id = AC.ParentId
WHERE 
    P.PostTypeId = 1  -- Only questions
ORDER BY 
    COALESCE(AC.TotalAnswers, 0) DESC;
