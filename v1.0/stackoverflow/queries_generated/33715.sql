WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(b.Class) AS BadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        (Upvotes - Downvotes + BadgePoints) AS NetReputation,
        ROW_NUMBER() OVER (ORDER BY (Upvotes - Downvotes + BadgePoints) DESC) AS Rank
    FROM 
        UserReputation
),

RecentUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
),

JoinedData AS (
    SELECT 
        mu.UserId,
        mu.DisplayName,
        mu.NetReputation,
        p.Title AS RecentPostTitle,
        p.CreationDate AS RecentPostDate,
        p.RecentPostRank
    FROM 
        MostActiveUsers mu
    LEFT JOIN 
        RecentUserPosts p ON mu.UserId = p.OwnerUserId
    WHERE 
        mu.Rank <= 10
)

SELECT 
    jd.UserId,
    jd.DisplayName,
    jd.NetReputation,
    jd.RecentPostTitle,
    jd.RecentPostDate
FROM 
    JoinedData jd
WHERE 
    jd.RecentPostRank = 1
ORDER BY 
    jd.NetReputation DESC;

-- Calculate total posts vs closed posts for a set benchmark
SELECT 
    p.OwnerUserId,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedPosts,
    ROUND((COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) * 100.0 / NULLIF(COUNT(p.Id), 0)), 2) AS ClosureRate
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.OwnerUserId
HAVING 
    TotalPosts > 5
ORDER BY 
    ClosureRate DESC;

