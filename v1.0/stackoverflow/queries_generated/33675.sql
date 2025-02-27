WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.Score,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only initial questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(DATEDIFF(Current_Time, u.CreationDate)) AS AvgAccountAgeDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rph.PostId,
    rph.Title,
    u.DisplayName AS Owner,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    uStats.TotalUpVotes,
    uStats.TotalDownVotes,
    uStats.TotalPosts,
    uStats.TotalBadges,
    uStats.AvgAccountAgeDays,
    CASE 
        WHEN rph.Score > 5 THEN 'Popular'
        WHEN rph.Score > 0 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM 
    RecursivePostHierarchy rph
JOIN 
    Users u ON rph.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteCounts pvc ON rph.PostId = pvc.PostId
JOIN 
    UserStats uStats ON u.Id = uStats.UserId
WHERE 
    rph.Level = 1 -- Only top level questions
ORDER BY 
    rph.Score DESC, 
    rph.CreationDate ASC
LIMIT 100;
