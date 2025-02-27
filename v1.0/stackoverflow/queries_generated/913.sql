WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Pos
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Upvotes) AS TotalUpvotes,
        SUM(rp.Downvotes) AS TotalDownvotes,
        COUNT(rp.PostId) AS PostCount
    FROM Users u
    JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id
    HAVING COUNT(rp.PostId) > 5
    ORDER BY TotalUpvotes DESC
    LIMIT 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.TotalUpvotes,
    u.TotalDownvotes,
    u.PostCount,
    COALESCE(rp.Title, 'No Title') AS RecentlyPostedTitle,
    rp.CreationDate AS RecentPostDate,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM TopUsers u
LEFT JOIN RecentPosts rp ON u.UserId = rp.OwnerUserId AND rp.Pos = 1
ORDER BY u.TotalUpvotes DESC;

-- Fetching posts linked to with a specific relationship
SELECT 
    pl.PostId, 
    pl.RelatedPostId, 
    COUNT(*) AS LinkCount
FROM PostLinks pl
JOIN Posts p ON pl.PostId = p.Id
WHERE p.ViewCount > 1000
GROUP BY pl.PostId, pl.RelatedPostId
HAVING COUNT(*) > 1;

-- Additional query to find the most common close reasons for posts
SELECT 
    p.CreatorUserId, 
    ct.Name AS CloseReason,
    COUNT(ph.Id) AS CloseReasonCount
FROM PostHistory ph
JOIN CloseReasonTypes ct ON ph.Comment::int = ct.Id
JOIN Posts p ON ph.PostId = p.Id
WHERE ph.PostHistoryTypeId IN (10, 11) -- When post is closed or reopened
GROUP BY p.OwnerUserId, ct.Name
HAVING COUNT(ph.Id) > 5
ORDER BY CloseReasonCount DESC;
