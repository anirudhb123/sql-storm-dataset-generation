WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation'
            WHEN Reputation BETWEEN 501 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM Users
), TagPostCounts AS (
    SELECT 
        TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY TagName
), RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
), TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS Downvotes,
        (COUNT(c.Id) FILTER (WHERE c.PostId IS NOT NULL)) AS CommentCount
    FROM Posts p 
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
    HAVING COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) > 0
    ORDER BY ViewCount DESC 
    LIMIT 10
), PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Upvotes,
        tp.Downvotes,
        tp.CommentCount,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        COUNT(DISTINCT b.UserId) FILTER (WHERE b.UserId IS NOT NULL) AS BadgeCount,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM TopPosts tp
    LEFT JOIN RecentPostHistory ph ON tp.PostId = ph.PostId AND ph.rn = 1
    LEFT JOIN Badges b ON b.UserId = ph.UserId
    GROUP BY tp.PostId, tp.Title, tp.ViewCount, tp.Upvotes, tp.Downvotes, tp.CommentCount, ph.UserDisplayName, ph.CreationDate
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Upvotes,
    pd.Downvotes,
    pd.CommentCount,
    pd.LastEditor,
    pd.LastEditDate,
    NULLIF(pd.BadgeCount, 0) AS UniqueBadges,
    COALESCE(utr.ReputationLevel, 'No Reputation') AS UserReputationLevel,
    tpc.PostCount AS TagPostCount,
    tpc.TotalViews AS TagTotalViews,
    pd.PostStatus
FROM PostDetails pd
LEFT JOIN UserReputation utr ON pd.LastEditor = utr.UserId
LEFT JOIN TagPostCounts tpc ON tpc.TagName = tpc.TagName 
ORDER BY pd.ViewCount DESC, pd.Upvotes DESC, pd.CommentCount DESC
LIMIT 20;

