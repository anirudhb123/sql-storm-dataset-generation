WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.PostTypeId,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        P2.Id,
        P2.Title,
        P2.OwnerUserId,
        P2.CreationDate,
        P2.PostTypeId,
        P2.ParentId,
        Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy RPH ON RPH.PostId = P2.ParentId
)

SELECT 
    U.DisplayName AS UserDisplayName,
    COUNT(DISTINCT RP.PostId) AS TotalQuestions,
    COUNT(DISTINCT AnswerPostId.PostId) AS TotalAnswers,
    SUM(CASE 
            WHEN RP.CreationDate < NOW() - INTERVAL '30 days' THEN 1 
            ELSE 0 
        END) AS QuestionsOlderThan30Days,
    AVG(ScoreHistory.Score) AS AverageScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed,
    BG.Class AS BadgeClass,
    COALESCE(NULLIF(bg_count, 0), 1) AS BadgeCount
FROM 
    Users U
LEFT JOIN 
    RecursivePostHierarchy RP ON U.Id = RP.OwnerUserId
LEFT JOIN 
    Votes V ON V.PostId = RP.PostId AND V.VoteTypeId = 2  -- Upvotes only
LEFT JOIN 
    (SELECT 
         PostId, 
         SUM(Score) AS Score 
     FROM 
         Votes 
     GROUP BY 
         PostId) ScoreHistory ON ScoreHistory.PostId = RP.PostId
LEFT JOIN 
    Badges BG ON BG.UserId = U.Id 
LEFT JOIN 
    (SELECT 
         Id, 
         UNNEST(string_to_array(Tags, ',')) AS TagName 
     FROM 
         Posts) T ON T.Id = RP.PostId
GROUP BY 
    U.Id, BG.Class
HAVING 
    COUNT(DISTINCT RP.PostId) > 5 
ORDER BY 
    TotalQuestions DESC, 
    AverageScore DESC;
