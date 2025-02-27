WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with top-level posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostUserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        u.DisplayName AS UserName,
        ph.Comment
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Only closed posts
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(b.BadgeCount, 0) AS UserBadges,
        RANK() OVER (ORDER BY COALESCE(v.TotalVotes, 0) DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN 
        PostUserBadges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter to recent posts
)
SELECT 
    rp.Title,
    rp.UpVotes,
    rp.DownVotes,
    rp.UserBadges,
    COALESCE(ch.Comment, 'No comments') AS ClosureComment,
    rph.Level AS PostLevel,
    rph.Title AS ParentPostTitle
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistory ch ON rp.Id = ch.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON rp.Id = rph.PostId
WHERE 
    rp.PostRank <= 10  -- Top 10 posts based on total votes
ORDER BY 
    rp.UpVotes DESC, 
    rp.DownVotes ASC;
