WITH RecursivePostCTE AS (
    -- CTE to find the hierarchy of posts and answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.PostTypeId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.PostTypeId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE cte ON p.ParentId = cte.PostId
),

PostMetrics AS (
    -- Calculate metrics for each post and its answers
    SELECT 
        p.Id,
        p.Title,
        SUM(COALESCE(v.VoteTypeId, 0) = 2) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId, 0) = 3) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges bh ON p.OwnerUserId = bh.UserId
    GROUP BY p.Id, p.Title
),

PostDetails AS (
    -- Combine post metrics with user details
    SELECT 
        pm.Id AS PostId,
        pm.Title,
        pm.UpVotes,
        pm.DownVotes,
        pm.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            ELSE 'Low Reputation'
        END AS ReputationStatus
    FROM PostMetrics pm
    JOIN Posts p ON pm.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
),

ClosedPostDetails AS (
    -- Get closed post details with reasons
    SELECT 
        d.PostId,
        d.Title,
        ph.Comment AS CloseReason,
        d.OwnerDisplayName,
        d.Reputation,
        d.ReputationStatus
    FROM PostDetails d
    LEFT JOIN PostHistory ph ON d.PostId = ph.PostId AND ph.PostHistoryTypeId = 10 -- Closed posts
),

FinalResults AS (
    SELECT 
        d.PostId,
        d.Title,
        COALESCE(c.CloseReason, 'Open') AS PostStatus,
        d.OwnerDisplayName,
        d.Reputation,
        d.ReputationStatus
    FROM PostDetails d
    LEFT JOIN ClosedPostDetails c ON d.PostId = c.PostId
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.PostStatus,
    fr.OwnerDisplayName,
    fr.Reputation,
    fr.ReputationStatus,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM FinalResults fr
LEFT JOIN LATERAL (
    SELECT 
        t.TagName
    FROM Tags t
    JOIN Posts p ON p.Id = t.ExcerptPostId
    WHERE p.Id = fr.PostId
) AS t ON TRUE
GROUP BY 
    fr.PostId, 
    fr.Title, 
    fr.PostStatus, 
    fr.OwnerDisplayName, 
    fr.Reputation, 
    fr.ReputationStatus
ORDER BY 
    fr.Reputation DESC,
    fr.PostStatus;
