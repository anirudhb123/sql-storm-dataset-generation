WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        r.Level + 1,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT 
        u.Id, 
        u.DisplayName,
        SUM(COALESCE(u.UpVotes, 0) - COALESCE(u.DownVotes, 0)) AS ReputationScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        q.OwnerUserId,
        COALESCE(vc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(vc.DownVoteCount, 0) AS DownVoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.PostHistoryCount, 0) AS PostHistoryCount,
        u.DisplayName
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS UpVoteCount 
         FROM 
             Votes 
         WHERE 
             VoteTypeId = 2 
         GROUP BY 
             PostId) AS vc ON p.Id = vc.PostId
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS CommentCount 
         FROM 
             Comments 
         GROUP BY 
             PostId) AS c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS PostHistoryCount 
         FROM 
             PostHistory 
         GROUP BY 
             PostId) AS ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts q ON p.AcceptedAnswerId = q.Id
    WHERE 
        p.PostTypeId = 1
),
AggregatedResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.CommentCount,
        r.UpVoteCount,
        r.DownVoteCount,
        oh.ReputationScore AS OwnerReputation
    FROM 
        PostStatistics r
    LEFT JOIN 
        UserReputation oh ON r.OwnerUserId = oh.Id
),
RankedResults AS (
    SELECT 
        a.PostId,
        a.Title,
        a.OwnerUserId,
        a.CommentCount,
        a.UpVoteCount,
        a.DownVoteCount,
        a.OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY a.OwnerReputation ORDER BY a.UpVoteCount DESC) AS Rank
    FROM 
        AggregatedResults a
)
SELECT 
    rh.Title AS PostTitle,
    rh.Level AS HierarchyLevel,
    ur.DisplayName AS OwnerName,
    CASE 
        WHEN rg.OwnerReputation IS NULL THEN 'No Reputation'
        ELSE CONCAT('Reputation: ', rg.OwnerReputation)
    END AS ReputationStatus,
    rg.CommentCount,
    rg.UpVoteCount,
    rg.DownVoteCount
FROM 
    RecursivePostHierarchy rh
LEFT JOIN 
    RankedResults rg ON rh.PostId = rg.PostId
LEFT JOIN 
    Users ur ON rh.OwnerUserId = ur.Id
WHERE 
    rh.Level = 0 
ORDER BY 
    rh.CreationDate DESC;
