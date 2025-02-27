WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    WHERE b.Class = 1 -- Gold badges
    GROUP BY b.UserId 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ub.BadgeNames,
        ub.BadgeCount
    FROM RankedPosts rp
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE rp.Rank <= 3
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(p.CommentCount, 0) AS TotalComments,
    p.UpVotes - p.DownVotes AS NetVotes,
    COALESCE(p.BadgeNames, 'No Badges') AS UserBadges,
    p.BadgeCount
FROM TopPosts p
ORDER BY p.Score DESC, p.CreationDate DESC
LIMIT 10;
