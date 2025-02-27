WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        ph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COUNT(co.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and Downvotes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
             PostId,
             COUNT(*) AS CommentCount
         FROM 
             Comments
         GROUP BY 
             PostId) co ON p.Id = co.PostId
    GROUP BY 
        p.Id, v.UpVotes, v.DownVotes, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        CASE 
            WHEN ps.UpVotes - ps.DownVotes > 0 THEN 'Positive'
            WHEN ps.UpVotes - ps.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        PostStatistics ps
    WHERE 
        ps.RowNum = 1
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
    p.Title,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount,
    ph.Level AS PostLevel,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    p.VoteSentiment
FROM 
    TopPosts p
LEFT JOIN 
    PostHierarchy ph ON p.PostId = ph.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    p.CommentCount > 10  -- Filtering for posts with more than 10 comments
ORDER BY 
    p.UpVotes DESC, p.DownVotes ASC;  -- Order by upvotes and downvotes
