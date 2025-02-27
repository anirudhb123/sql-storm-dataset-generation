
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerName,
        COALESCE(cm.CommentCount, 0) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) cm ON p.Id = cm.PostId
    WHERE p.CreationDate >= '2023-10-01 12:34:56'
),
PostWithMaxVotes AS (
    SELECT 
        p.Id AS PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
    HAVING SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) > 0
),
RecentBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount, 
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM Badges b
    WHERE b.Date >= '2024-04-01 12:34:56' 
    GROUP BY b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.OwnerName,
    rp.CommentCount,
    COALESCE(pwv.TotalVotes, 0) AS TotalVotes,
    rb.BadgeCount,
    rb.BadgeNames
FROM RankedPosts rp
LEFT JOIN PostWithMaxVotes pwv ON rp.PostId = pwv.PostId
LEFT JOIN RecentBadges rb ON rp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = rb.UserId)
WHERE rp.Rank <= 10
ORDER BY rp.Score DESC, rp.ViewCount DESC;
