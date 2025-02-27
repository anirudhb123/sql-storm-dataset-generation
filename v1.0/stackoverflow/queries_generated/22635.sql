WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),

TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeScore,
        RANK() OVER (ORDER BY ur.Reputation + ur.BadgeScore DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    tu.UserId,
    tu.Reputation,
    tu.BadgeScore
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.PostRank = 1
    AND (rp.Score IS NULL OR rp.Score > 10)
    AND rp.ViewCount IS NOT NULL
    AND (DATE_PART('dow', rp.CreationDate) IN (0, 6) OR (EXTRACT(HOUR FROM rp.CreationDate) BETWEEN 8 AND 18))
ORDER BY 
    tu.UserRank, rp.ViewCount DESC
LIMIT 100;

-- Additional complex constructs
SELECT 
    ps.Id AS PostId,
    ARRAY_AGG(DISTINCT tt.TagName) AS Tags,
    COUNT(DISTINCT c.Id) FILTER (WHERE c.CreationDate > CURRENT_DATE - INTERVAL '6 months') AS RecentComments,
    MAX(v.VoteTypeId) FILTER (WHERE v.CreationDate IS NOT NULL) AS HighestVoteType,
    CASE 
        WHEN MAX(b.Class) IS NULL THEN 'No Badge'
        ELSE 
            CASE
                WHEN MAX(b.Class) = 1 THEN 'Gold Badge'
                WHEN MAX(b.Class) = 2 THEN 'Silver Badge'
                ELSE 'Bronze Badge'
            END
    END AS BadgeCategory
FROM 
    Posts ps
LEFT JOIN 
    Comments c ON c.PostId = ps.Id
LEFT JOIN 
    Votes v ON v.PostId = ps.Id
LEFT JOIN 
    LATERAL (SELECT * FROM string_to_array(substring(ps.Tags, 2, length(ps.Tags)-2), '><')) AS t(Tag) 
LEFT JOIN 
    Tags tt ON tt.TagName = t.Tag
LEFT JOIN 
    Badges b ON b.UserId = ps.OwnerUserId
WHERE 
    ps.CreationDate >= '2020-01-01'
GROUP BY 
    ps.Id
HAVING 
    COUNT(c.Id) > 5
ORDER BY 
    ps.CreationDate DESC
LIMIT 50;
