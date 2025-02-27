WITH RecursiveBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), 

RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CountComments, 0) AS CommentCount,
        COALESCE(v.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(v.DownvoteCount, 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CountComments
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
), 

PostDerivedData AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        COALESCE(rp.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(rp.DownvoteCount, 0) AS DownvoteCount
    FROM Posts p
    LEFT JOIN RecursiveBadgeCounts bc ON p.OwnerUserId = bc.UserId
    LEFT JOIN RecentPostActivity rp ON p.Id = rp.PostId
    WHERE p.OwnerUserId IS NOT NULL
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.CommentCount,
    p.UpvoteCount,
    p.DownvoteCount,
    (p.UpvoteCount - p.DownvoteCount) AS Score,
    CASE 
        WHEN p.BadgeCount > 0 THEN 'Active Contributor'
        WHEN p.CommentCount > 10 THEN 'Frequent Commenter'
        ELSE 'New User'
    END AS UserType
FROM PostDerivedData p
WHERE Score > 0
ORDER BY Score DESC, p.CreationDate DESC
LIMIT 50;

-- This query retrieves posts created in the last month, includes user badge counts, comment and vote statistics, computes a "score" for each post, and classifies users based on their activity. It combines various SQL constructs (CTEs, window functions, COALESCE) to provide an elaborate overview of recent post activity.
