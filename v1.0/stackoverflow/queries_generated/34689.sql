WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Only answers

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.Id = r.ParentId
)
, PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
, MostVotedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        pvc.UpVotes,
        pvc.DownVotes,
        pvc.TotalVotes,
        ph.CreationDate,
        ROW_NUMBER() OVER (ORDER BY pvc.TotalVotes DESC) AS Rank
    FROM 
        RecursivePostHierarchy ph
    JOIN 
        PostVoteCounts pvc ON ph.PostId = pvc.PostId
    WHERE 
        ph.Level = 1 -- We want the top level answers only
)
, UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.Location,
    u.Views,
    ubc.BadgeCount,
    mv.Title AS MostVotedPostTitle,
    mv.UpVotes,
    mv.DownVotes,
    mv.TotalVotes
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN 
    MostVotedPosts mv ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = mv.PostId) 
WHERE 
    u.Reputation > 1000
AND 
    ubc.BadgeCount IS NOT NULL
ORDER BY 
    u.Reputation DESC
LIMIT 10;
