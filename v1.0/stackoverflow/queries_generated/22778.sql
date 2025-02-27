WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.Tags,
        COALESCE(p.ClosedDate, '9999-12-31') AS ClosureDate
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    CASE 
        WHEN rp.ClosureDate < NOW() THEN 'Closed'
        ELSE 'Open'
    END AS Status,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Hot Post'
        ELSE 'Regular Post'
    END AS Popularity,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
    MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
    MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
FROM RankedPosts rp
LEFT JOIN PostsTags pt ON rp.Id = pt.PostId
LEFT JOIN Tags t ON pt.TagId = t.Id
LEFT JOIN Badges b ON rp.OwnerUserId = b.UserId
WHERE 
    rp.PostRank = 1 
    AND rp.Reputation > 100 
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes v
        WHERE v.PostId = rp.Id AND v.VoteTypeId = 2
    )
GROUP BY rp.Title, rp.Score, rp.ViewCount, rp.ClosureDate
HAVING COUNT(DISTINCT t.Id) > 2
ORDER BY rp.Score DESC;
This SQL query generates a report for popular posts created in the last year, filtering based on various criteria and including additional analytics such as tag aggregation and badge counts. It incorporates CTEs, window functions, string operations, and complex predicates for an elaborate analytics task.
