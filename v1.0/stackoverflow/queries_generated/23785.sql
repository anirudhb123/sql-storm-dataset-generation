WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserVotes AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(up.UpVotes, 0) - COALESCE(down.DownVotes, 0) AS NetVotes,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    MAX(rp.ViewCount) AS MaxViewCount,
    MAX(CASE WHEN rp.PostRank = 1 THEN rp.Score ELSE NULL END) AS TopScore
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    UserVotes up ON u.Id = up.UserId
LEFT JOIN 
    UserVotes down ON u.Id = down.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, b.BadgeCount, b.BadgeNames
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    NetVotes DESC,
    MAXViewCount DESC
FETCH FIRST 10 ROWS ONLY;

This query demonstrates several advanced SQL concepts:

1. Common Table Expressions (CTEs) that perform ranking, aggregation, and rolling up of data.
2. Window functions for ranking posts based on their scores per user.
3. String aggregation to combine the names of badges owned by each user.
4. Conditional aggregation to count upvotes and downvotes.
5. Complex predicates with COALESCE to manage NULL values and ensure calculations are performed correctly.
6. Outer joins to include users even if they have no posts or badges.
7. A HAVING clause that filters users based on aggregate conditions.
8. Order by multiple criteria to prioritize results.
9. A limit on the number of results returned. 

This complex query evaluates users with respect to their posts, badges, and votes, providing a snapshot of user engagement in a manner that goes beyond simple metrics.
