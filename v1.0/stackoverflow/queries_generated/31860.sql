WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        p.CreationDate,
        p.LastActivityDate,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        VoteSummary v ON p.Id = v.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.UpVotes,
    p.DownVotes,
    p.TotalVotes,
    p.Score,
    ub.BadgeCount,
    ph.Level AS PostLevel,
    STRING_AGG(t.TagName, ', ') AS TagsList -- Aggregate tags associated
FROM 
    PostWithVotes p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    RecursivePostHierarchy ph ON p.PostId = ph.PostId
LEFT JOIN 
    Posts p_tags ON p.PostId = p_tags.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p_tags.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for recent posts
GROUP BY 
    p.PostId, u.DisplayName, p.UpVotes, p.DownVotes, p.TotalVotes, p.Score, ub.BadgeCount, ph.Level
ORDER BY 
    p.Score DESC, p.UpVotes DESC, p.CreationDate DESC
LIMIT 100;
