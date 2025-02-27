WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        ParentId,
        CreationDate,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 2  -- Start with all answers
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.ParentId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
PostLinksSummary AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS TotalLinks
    FROM 
        PostLinks PL
    GROUP BY 
        PL.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    P.Title,
    COALESCE(L.TotalLinks, 0) AS RelatedPostLinks,
    P.CreationDate,
    P.Score,
    COUNT(DISTINCT PH.Id) AS AnswerLevel
FROM 
    Users U
JOIN 
    UserReputation UR ON U.Id = UR.UserId
JOIN 
    Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Only questions
LEFT JOIN 
    PostLinksSummary L ON P.Id = L.PostId
LEFT JOIN 
    RecursivePostHierarchy PH ON PH.ParentId = P.Id
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    U.Id, U.DisplayName, P.Id, P.Title, L.TotalLinks, P.CreationDate, P.Score
HAVING 
    COUNT(DISTINCT PH.Id) > 0  -- Only questions with answers
ORDER BY 
    ReputationRank, RelatedPostLinks DESC, P.CreationDate DESC;
