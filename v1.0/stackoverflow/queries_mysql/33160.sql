
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),

ClosePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS CloserUserId,
        TIMESTAMPDIFF(MINUTE, ph.CreationDate, CURRENT_TIMESTAMP) AS MinutesSinceClose
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.Score, 0) AS PostScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN (
        SELECT tag.TagName
        FROM Posts p
        JOIN (
            SELECT UNNEST(STRING_SPLIT(p.Tags, ',')) AS TagName
        ) AS tag ON tag.TagName IS NOT NULL
    ) AS t ON t.TagName IS NOT NULL
    WHERE p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score
),

RankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.PostScore,
        rp.CommentCount,
        rp.VoteCount,
        rp.Tags,
        ROW_NUMBER() OVER (ORDER BY rp.PostScore DESC, rp.ViewCount DESC) AS PostRank
    FROM RecentPosts rp
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    p.PostId,
    p.Title,
    p.ViewCount,
    p.PostScore,
    p.CommentCount,
    p.VoteCount,
    p.PostRank,
    cp.CloseDate,
    cp.MinutesSinceClose
FROM UserReputation ur
LEFT JOIN RankedPosts p ON p.PostId = ur.UserId
LEFT JOIN ClosePostHistory cp ON p.PostId = cp.PostId
WHERE ur.Reputation > 1000  
ORDER BY ur.ReputationRank, p.PostRank;
