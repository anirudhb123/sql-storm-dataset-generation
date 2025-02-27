WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        OwnerUserId,
        CreationDate,
        0 AS Depth
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Start with top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        ph.RevisionGUID,
        ph.CreationDate AS LastEditDate,
        ph.Comment AS EditComment,
        COALESCE(ps.UpVoteCount, 0) AS UpVotes,
        COALESCE(ps.DownVoteCount, 0) AS DownVotes,
        COALESCE(bs.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(bs.BadgeNames, '') AS UserBadges,
        100.0 * COALESCE(ps.UpVoteCount, 0) / NULLIF((COALESCE(ps.UpVoteCount, 0) + COALESCE(ps.DownVoteCount, 0)), 0) AS VoteRatio
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Edit title or body
    LEFT JOIN 
        PostVoteStats ps ON p.Id = ps.PostId
    LEFT JOIN 
        UserBadges bs ON u.Id = bs.UserId
)
SELECT 
    rph.Id AS PostId,
    rph.Title,
    rph.Depth,
    pd.OwnerDisplayName,
    pd.LastEditDate,
    pd.EditComment,
    pd.UpVotes,
    pd.DownVotes,
    pd.UserBadgeCount,
    pd.UserBadges,
    pd.VoteRatio
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostDetails pd ON rph.Id = pd.PostId
WHERE 
    rph.Depth <= 2 -- Limit to a depth of 2 for hierarchy
ORDER BY 
    rph.Depth, rph.CreationDate DESC;
