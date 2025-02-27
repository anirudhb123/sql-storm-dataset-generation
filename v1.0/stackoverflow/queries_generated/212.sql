WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserStatistics AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) as TotalPosts,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) as TotalBadges
    FROM Users u
    WHERE u.Reputation > 1000
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounties
FROM UserStatistics up
JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE rp.Rank <= 3 -- Top 3 latest posts for each user
AND (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) > 5 -- More than 5 upvotes
ORDER BY up.Reputation DESC, rp.CreationDate DESC
OPTION (RECOMPILE);
