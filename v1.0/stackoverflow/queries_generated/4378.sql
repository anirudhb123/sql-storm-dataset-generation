WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName,
        CASE 
            WHEN p.OwnerUserId IS NULL THEN 'Community User'
            ELSE u.DisplayName 
        END AS OwnerName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.OwnerName,
        COALESCE(rp.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(rp.DownvoteCount, 0) AS DownvoteCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10) THEN 'Closed'
            ELSE 'Open' 
        END AS PostStatus
    FROM RecentPosts rp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerName,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    pd.PostStatus,
    ur.Reputation AS OwnerReputation,
    ur.ReputationRank
FROM PostDetails pd
LEFT JOIN UserReputation ur ON pd.OwnerName = ur.UserId
WHERE pd.Score > 10
ORDER BY pd.CreationDate DESC, ur.Reputation DESC;

