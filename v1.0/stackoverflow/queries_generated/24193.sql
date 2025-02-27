-- Performance benchmarking complex SQL query involving various constructs
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(co.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int) )
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(b.Class) AS TotalBadgeClass 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id
),
FilteredUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.TotalBadgeClass,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.BadgeCount > 2 
        AND ur.Reputation BETWEEN 1000 AND 10000
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    u.DisplayName AS TopUser,
    fu.UserRank,
    fu.Reputation AS UserReputation,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score > 100 THEN 'High Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    COUNT(*) OVER (PARTITION BY rp.PostRank) AS PostsPerUser
FROM 
    RankedPosts rp
JOIN 
    FilteredUsers fu ON rp.PostRank = 1
JOIN 
    Users u ON fu.UserId = u.Id
WHERE 
    rp.CreationDate = (
        SELECT MAX(rp_inner.CreationDate) 
        FROM RankedPosts rp_inner 
        WHERE rp_inner.OwnerUserId = rp.OwnerUserId
    )
ORDER BY 
    rp.Score DESC, fu.UserReputation DESC
FETCH FIRST 10 ROWS ONLY;

