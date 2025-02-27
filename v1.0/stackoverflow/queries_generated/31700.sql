WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        0 AS Level,
        p.ParentId
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        Level + 1,
        p.ParentId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
RankedPostVotes AS (
    SELECT 
        p.Id,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS RankByVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.CreationDate,
        ph.Level,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(r.PlayerCount, 0) AS PlayerCount
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        RankedPostVotes v ON p.Id = v.Id
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(DISTINCT PostId) AS PlayerCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 -- Upvotes
        GROUP BY 
            OwnerUserId
    ) r ON p.OwnerUserId = r.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
)
SELECT 
    u.DisplayName,
    COUNT(pa.PostId) AS PostsCount,
    AVG(pa.Score) AS AverageScore,
    SUM(pa.VoteCount) AS TotalVotes,
    MAX(pa.CreationDate) AS LastPostDate
FROM 
    Users u
JOIN 
    PostAnalytics pa ON u.Id = pa.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    AVG(pa.Score) > 10 AND COUNT(pa.PostId) > 5 -- Interested only in users with high activity
ORDER BY 
    TotalVotes DESC
LIMIT 10;
