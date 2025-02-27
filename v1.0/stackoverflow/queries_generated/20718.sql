WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate > NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentVotes AS (
    SELECT
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 1) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE
        v.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
EnhancedPostStats AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        ur.Reputation AS UserReputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        rv.TotalVotes,
        rv.UpVotes,
        rv.DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON ur.UserId = u.Id
    LEFT JOIN 
        RecentVotes rv ON rv.PostId = rp.PostId
)
SELECT 
    eps.PostId,
    eps.Title,
    eps.Score,
    eps.ViewCount,
    eps.CreationDate,
    eps.UserReputation,
    eps.GoldBadges,
    eps.SilverBadges,
    eps.BronzeBadges,
    COALESCE(eps.TotalVotes, 0) AS TotalVotes,
    COALESCE(eps.UpVotes, 0) AS UpVotes,
    COALESCE(eps.DownVotes, 0) AS DownVotes
FROM 
    EnhancedPostStats eps
WHERE 
    eps.Score >= 0
    AND eps.UserReputation > 1000
    AND EPS.UserReputation NOT IN (SELECT UserId FROM Users WHERE Reputation < 0)
ORDER BY 
    eps.Score DESC, eps.ViewCount DESC
LIMIT 
    10;

-- The following will validate some peculiar scenarios including NULL checks
SELECT
    p.Id AS PostId,
    COALESCE(NULLIF(p.Title, ''), 'Untitled Post') AS DisplayTitle,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) THEN 'Popular'
        ELSE 'Not Popular' 
    END AS PopularityStatus,
    CASE 
        WHEN p.OwnerUserId IS NULL THEN 'Unknown User'
        ELSE (SELECT DisplayName FROM Users WHERE Id = p.OwnerUserId)
    END AS OwnerDisplayName
FROM 
    Posts p
WHERE 
    p.CreationDate >= '2020-01-01'
    AND p.ViewCount IS NOT NULL
    AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
ORDER BY 
    p.CreationDate DESC;
