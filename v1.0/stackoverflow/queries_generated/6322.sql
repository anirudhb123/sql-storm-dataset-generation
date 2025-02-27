WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM RankedPosts rp
    WHERE rp.PostRank <= 5
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    ub.BadgeCount
FROM TopPosts tp
LEFT JOIN UserBadges ub ON tp.OwnerUserId = ub.UserId
ORDER BY tp.Score DESC, tp.CreationDate ASC;
