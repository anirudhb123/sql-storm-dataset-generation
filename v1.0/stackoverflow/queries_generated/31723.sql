WITH RecursivePostHierarchy AS (
    -- CTE to get all answers related to questions and their respective paths
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        1 AS Level,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.ParentId,
        P.Title,
        PH.Level + 1,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy PH ON P.ParentId = PH.PostId
)

SELECT 
    PH.PostId,
    PH.Title,
    PH.Level,
    PH.CreationDate,
    PH.Score,
    PH.ViewCount,
    PH.OwnerDisplayName,
    COALESCE(C.Count, 0) AS CommentCount,
    COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(V.DownVoteCount, 0) AS DownVoteCount,
    CASE 
        WHEN PH.ViewCount > 1000 THEN 'High View'
        WHEN PH.ViewCount BETWEEN 500 AND 1000 THEN 'Medium View'
        ELSE 'Low View'
    END AS ViewTier,
    ROW_NUMBER() OVER (PARTITION BY PH.Level ORDER BY PH.Score DESC) AS RankWithinLevel
FROM 
    RecursivePostHierarchy PH
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS Count 
    FROM Comments 
    GROUP BY PostId) C ON PH.PostId = C.PostId
LEFT JOIN 
    (SELECT PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Votes 
    GROUP BY PostId) V ON PH.PostId = V.PostId
LEFT JOIN 
    Tags T ON T.Id = (SELECT MIN(Id) FROM Tags WHERE T.TagName = ANY(string_to_array(PH.Title, ' ')))

WHERE 
    PH.Level <= 2
ORDER BY 
    PH.Level, PH.Score DESC;

-- This query retrieves posts and their answers, calculates comment counts,
-- aggregates upvote/downvote information, classifies posts based on view count,
-- and generates a ranking within each level of answers related to questions.
