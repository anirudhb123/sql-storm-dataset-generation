WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
FilteredPosts AS (
    SELECT 
        p.*,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id
),
PostWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        b.Name AS BadgeName,
        b.Class,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, b.Name, b.Class
),
PostStats AS (
    SELECT 
        f.*,
        COALESCE(b.BadgeName, 'No Badge') AS BadgeName,
        COALESCE(b.Class, 3) AS BadgeClass,
        SUM(f.UpVotes - f.DownVotes) OVER (PARTITION BY f.OwnerUserId ORDER BY f.LastActivityDate DESC) AS Score
    FROM 
        FilteredPosts f
    LEFT JOIN PostWithBadges b ON f.OwnerUserId = b.UserId
    WHERE 
        f.rn = 1 -- Latest version of the post
)
SELECT 
    p.Title,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.Score,
    b.BadgeName,
    b.BadgeClass,
    CASE 
        WHEN p.BadgeClass = 1 THEN 'Gold'
        WHEN p.BadgeClass = 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS BadgeClassName,
    r.PostId AS RelatedPostId
FROM 
    PostStats p
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
LEFT JOIN RecursivePostHierarchy r ON pl.RelatedPostId = r.PostId
ORDER BY 
    p.Score DESC,
    p.Title;
