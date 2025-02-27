WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2 -- and getting answers
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON pl.RelatedPostId = t.WikiPostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.UserId IS NOT NULL) AS TotalVotes,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.ViewCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.CommentCount,
    pm.BadgeCount,
    pm.Tags,
    ua.DisplayName AS OwnerDisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.TotalVotes,
    ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.Level) AS AnswerLevel
FROM 
    RecursivePostHierarchy ph
JOIN 
    PostMetrics pm ON pm.Id = ph.PostId
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    UserActivity ua ON ua.UserId = u.Id
WHERE 
    pm.UpVotes > pm.DownVotes AND 
    pm.CommentCount > 0
ORDER BY 
    pm.ViewCount DESC, 
    pm.UpVotes DESC;

