WITH RECURSIVE PostHierarchy AS (
    -- CTE to get the hierarchy of posts, including questions and their answers
    SELECT
        Id,
        Title,
        PostTypeId,
        ParentId,
        CreationDate,
        1 AS Depth
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
    WHERE 
        p.PostTypeId = 2 -- Answers
),
PostViews AS (
    -- Counting views grouped by users and filtering NULLs for clarity
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.ViewCount) AS TotalViews
    FROM
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserMetrics AS (
    -- Collecting users' reputation and calculating a metric based on votes and views
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(pv.TotalViews, 0) AS TotalViews,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(pv.TotalViews, 0) + COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS EngagementMetric
    FROM 
        Users u
    LEFT JOIN 
        PostViews pv ON u.Id = pv.UserId
    LEFT JOIN 
        (SELECT 
            UserId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            UserId) v ON u.Id = v.UserId
),
PostHistoryAggregated AS (
    -- Aggregate history of posts including modification counts and close reasons
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(ph.Id) AS TotalHistory
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    um.TotalViews,
    um.UpVotes,
    um.DownVotes,
    um.EngagementMetric,
    ph.Title AS PostTitle,
    ph.Depth,
    pha.CloseCount,
    pha.TotalHistory
FROM 
    Users u
JOIN 
    UserMetrics um ON u.Id = um.UserId
JOIN 
    PostHierarchy ph ON u.Id = ph.OwnerUserId
JOIN 
    PostHistoryAggregated pha ON ph.Id = pha.PostId
WHERE 
    um.EngagementMetric > 0
ORDER BY 
    um.EngagementMetric DESC, 
    um.Reputation DESC
LIMIT 100;
