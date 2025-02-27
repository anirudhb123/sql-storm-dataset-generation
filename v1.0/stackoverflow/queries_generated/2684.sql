WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'Active Contributor' 
            WHEN u.Reputation BETWEEN 500 AND 999 THEN 'Moderate Contributor' 
            ELSE 'New Contributor' 
        END AS ContributorLevel
    FROM Users u
),
PostWithUser AS (
    SELECT 
        rp.*,
        ur.Reputation,
        ur.ContributorLevel
    FROM RecentPosts rp
    LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
)

SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount,
    p.ViewCount,
    COALESCE(ROUND((p.UpVotes::float / NULLIF((p.UpVotes + p.DownVotes), 0)) * 100, 2), 0) AS ApprovalRate,
    p.Reputation,
    p.ContributorLevel,
    CASE 
        WHEN p.CommentCount > 5 THEN 'Highly Engaged'
        WHEN p.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Engaged'
        ELSE 'Not Engaged'
    END AS EngagementLevel
FROM PostWithUser p
ORDER BY p.CreationDate DESC
LIMIT 100;

-- Additionally, find duplicate posts based on title and disallow duplicates in the result set
SELECT 
    p.Id,
    p.Title,
    COUNT(*) AS DuplicateCount
FROM Posts p
JOIN Posts p2 ON p.Title = p2.Title AND p.Id <> p2.Id
GROUP BY p.Id, p.Title
HAVING COUNT(*) > 1;
