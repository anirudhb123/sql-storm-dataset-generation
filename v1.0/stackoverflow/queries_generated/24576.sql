WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
        AND p.ViewCount > 0
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS PostCount
    FROM 
        Users u
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(LEFT(p.Tags, LENGTH(p.Tags) - 1), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPostReasons AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        ARRAY_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
    GROUP BY 
        p.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    upr.Reputation,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    cp.LastClosedDate,
    cp.CloseReasons
FROM 
    UserReputation upr
JOIN 
    Users up ON upr.UserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    ClosedPostReasons cp ON rp.PostId = cp.PostId
WHERE 
    upr.PostCount > 10
    AND rp.OwnerPostRank = 1 -- highest most recent post
    AND (hp.LastClosedDate IS NULL OR hp.LastClosedDate < rp.CreationDate)
ORDER BY 
    upr.Reputation DESC,
    rp.Score DESC
LIMIT 50;
This SQL query accomplishes a complex performance benchmarking task in the StackOverflow schema by leveraging multiple Common Table Expressions (CTEs). It ranks posts, associates users with badges, and filters results with complicated predicates including a combination of NOT NULL checks, and interval comparisons to derive meaningful insights from the dataset. Each part of the query highlights various SQL capabilities such as window functions, set operators, and outer joins, providing a rich dataset suitable for analysis and benchmarking.
