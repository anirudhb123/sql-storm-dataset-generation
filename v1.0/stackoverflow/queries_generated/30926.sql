WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        ph.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        u.Views,
        (SELECT COUNT(*) FROM Posts po WHERE po.OwnerUserId = u.Id) AS TotalPosts,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges
    FROM 
        Users u 
    WHERE 
        u.Reputation > 100 AND
        u.Views < 1000
),
RecentVotes AS (
    SELECT 
        v.PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        v.PostId, vt.Name
)
SELECT 
    ph.PostId,
    ph.Title,
    u.DisplayName AS OwnerName,
    u.Location,
    u.Reputation,
    u.TotalPosts,
    v.VoteType,
    v.VoteCount,
    ph.Depth,
    'Rank: ' || COALESCE(rp.PostRank::text, 'N/A') AS PostRank,
    (SELECT STRING_AGG( DISTINCT t.TagName, ', ' ORDER BY t.TagName) 
     FROM Tags t
     JOIN regexp_split_to_table(p.Tags, ',') AS tag ON tag = t.TagName) AS Tags
FROM 
    PostHierarchy ph
LEFT JOIN 
    RankedPosts rp ON ph.PostId = rp.PostId
INNER JOIN 
    FilteredUsers u ON rp.OwnerUserId = u.UserId
LEFT JOIN 
    RecentVotes v ON ph.PostId = v.PostId
WHERE 
    ph.Depth > 1
ORDER BY 
    u.Reputation DESC, 
    ph.Title;

