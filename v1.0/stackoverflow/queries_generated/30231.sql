WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.PostId) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    MAX(v.CreationDate) AS LastVoteDate,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(UNNEST(string_to_array(p.Tags, ','))) AS TagName
    ) t ON TRUE
WHERE 
    u.Reputation >= 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    AverageScore DESC
FETCH FIRST 10 ROWS ONLY;

-- Benchmarking query improved with window functions and inner-outer join structures 
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalScore,
    u.TotalPosts,
    CASE 
        WHEN u.TotalScore IS NULL THEN 'No Posts Yet'
        ELSE 'Active'
    END AS Status,
    MAX(CASE WHEN rp.PostRank = 1 THEN rp.Title END) AS TopPostTitle
FROM 
    UserScores u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
GROUP BY 
    u.UserId, u.DisplayName, u.TotalScore, u.TotalPosts
ORDER BY 
    u.TotalScore DESC
LIMIT 10;

-- To evaluate the effect of NULLs in scoring systems   
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS QuestionCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    u.DisplayName
HAVING 
    TotalScore > 100
ORDER BY 
    TotalScore DESC;

