WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Only counting UpVotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(b.Class = 1)::int AS GoldBadges, 
        SUM(b.Class = 2)::int AS SilverBadges, 
        SUM(b.Class = 3)::int AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Bounty start and close votes
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(b.Class) >= 2  -- User must have at least 2 badges
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    pu.UserId,
    pu.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScores,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(tp.TotalBounties) AS TotalBounties,
    MAX(ph.HistoryTypes) AS AllPostHistoryTypes,
    MAX(ph.LastHistoryDate) AS MostRecentHistoryDate
FROM 
    TopUsers tp
JOIN 
    Users pu ON tp.UserId = pu.Id
JOIN 
    Posts rp ON rp.OwnerUserId = pu.Id
LEFT JOIN 
    PostHistoryInfo ph ON rp.Id = ph.PostId
WHERE 
    pu.Reputation > 1000  -- Only consider users with reputation greater than 1000
GROUP BY 
    pu.UserId, pu.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5  -- User must have authored more than 5 posts
ORDER BY 
    TotalScores DESC, TotalPosts DESC
LIMIT 10;
