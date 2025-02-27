WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        rh.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy rh ON p.ParentId = rh.PostId
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 OR b.Class = 2 -- Gold or Silver badges
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(c.CreationDate) AS LastCommentDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    p.CreationDate AS PostCreationDate,
    pp.UpVotes,
    pp.DownVotes,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ra.LastCommentDate, 'No comments') AS LastComment,
    COALESCE(ra.CommentCount, 0) AS TotalComments,
    COALESCE(rh.Level, 1) AS HierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    PostVotes pp ON p.Id = pp.PostId
LEFT JOIN 
    PostBadges pb ON p.OwnerUserId = pb.UserId
LEFT JOIN 
    RecentActivity ra ON p.Id = ra.PostId
LEFT JOIN 
    RecursivePostHierarchy rh ON p.Id = rh.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
ORDER BY 
    pp.UpVotes DESC,
    p.CreationDate DESC

