WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.LastAccessDate > NOW() - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    au.DisplayName AS OwnerName,
    au.Reputation AS OwnerReputation,
    au.Views AS OwnerViews,
    au.BadgeCount,
    pha.EditCount,
    pha.LastEdited
FROM RankedPosts rp
JOIN ActiveUsers au ON rp.OwnerUserId = au.UserId
LEFT JOIN PostHistoryAggregated pha ON rp.PostId = pha.PostId
WHERE rp.rn = 1 -- Select latest questions per user
ORDER BY rp.CreationDate DESC
LIMIT 100;
