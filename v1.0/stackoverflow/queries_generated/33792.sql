WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        Level + 1 AS Level,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.LastActivityDate,
    uv.DisplayName AS OwnerDisplayName,
    ps.PostsCount,
    ps.CommentsCount,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN pv.UpVotes - pv.DownVotes > 0 THEN 'Positive'
        WHEN pv.UpVotes - pv.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment,
    r.Level AS HierarchyLevel,
    DENSE_RANK() OVER (PARTITION BY r.Level ORDER BY pv.UpVotes DESC) AS RankByUpVotes
FROM 
    RecursivePostHierarchy r
JOIN 
    UserStatistics ps ON r.OwnerUserId = ps.UserId
JOIN 
    PostVoteDetails pv ON r.PostId = pv.PostId
WHERE 
    r.Level <= 2 -- Consider only top-level and second-level posts
    AND pv.UpVotes > 0 -- Only include posts with at least one upvote
ORDER BY 
    r.Level, pv.UpVotes DESC;
