WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12) -- closed, reopened, deleted
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS TotalUpvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.PostDate,
        pd.LastActivityDate,
        pd.CommentCount,
        pd.TotalUpvotes,
        COALESCE(rph.PostHistoryTypeId, 0) AS LastAction
    FROM PostDetails pd
    LEFT JOIN RecentPostHistory rph ON pd.PostId = rph.PostId AND rph.rn = 1
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    f.PostId,
    f.Title,
    f.PostDate,
    f.LastActivityDate,
    f.CommentCount,
    f.TotalUpvotes,
    CASE 
        WHEN f.LastAction = 10 THEN 'Closed'
        WHEN f.LastAction = 11 THEN 'Reopened'
        WHEN f.LastAction = 12 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM UserActivity ua
LEFT JOIN FilteredPosts f ON f.PostId IN (
    SELECT p.Id
    FROM Posts p
    WHERE p.OwnerUserId = ua.UserId
    AND p.LastActivityDate > NOW() - INTERVAL '30 days'
)
ORDER BY ua.Reputation DESC, f.LastActivityDate DESC;
