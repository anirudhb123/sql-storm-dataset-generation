WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostWithVoteCount AS (
    SELECT 
        p.Id,
        p.Title,
        p.AverageScore,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(r.Level, 0) AS HierarchyLevel
    FROM 
        Posts p
    LEFT JOIN 
        UserVoteStats v ON p.OwnerUserId = v.UserId
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.Id
),

FilteredPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY HierarchyLevel ORDER BY AverageScore DESC) AS RankByScore
    FROM 
        PostWithVoteCount
    WHERE 
        TotalVotes > 0
)

SELECT 
    FP.Title,
    FP.TotalVotes,
    FP.UpVotes,
    FP.DownVotes,
    FP.HierarchyLevel,
    FP.RankByScore,
    U.Reputation,
    U.CreationDate
FROM 
    FilteredPosts FP
JOIN 
    Users U ON FP.OwnerUserId = U.Id
WHERE 
    FP.RankByScore <= 10
ORDER BY 
    FP.HierarchyLevel, FP.RankByScore;
