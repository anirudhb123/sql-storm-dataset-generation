WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
UserScoreStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPostsCreated
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 -- Filter only users with reputation > 100
    GROUP BY 
        u.Id
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    ph.PostId,
    ph.Title,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(us.TotalScore, 0) AS UserScore,
    COALESCE(us.TotalPostsCreated, 0) AS UserPostCount,
    ph.Level AS HierarchyLevel,
    RE.Date AS RecentEdits,
    CASE 
        WHEN RE.LastEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    PostHierarchy ph
LEFT JOIN 
    VoteStats vs ON ph.PostId = vs.PostId
LEFT JOIN 
    Users u ON ph.PostId = u.OwnerUserId
LEFT JOIN 
    UserScoreStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentEdits RE ON ph.PostId = RE.PostId
ORDER BY 
    ph.Level, ph.Title;
