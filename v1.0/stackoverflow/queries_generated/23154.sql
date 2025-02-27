WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TotalVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.GoldBadges), 0) AS TotalGold,
        COALESCE(SUM(b.SilverBadges), 0) AS TotalSilver,
        COALESCE(SUM(b.BronzeBadges), 0) AS TotalBronze
    FROM 
        Users u
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(b.GoldBadges) > 0
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    t.DisplayName AS TopUser,
    r.Title AS LatestPost,
    r.Score,
    tv.Upvotes,
    tv.Downvotes,
    r.CreationDate,
    CASE 
        WHEN tv.Upvotes IS NULL THEN 'No Upvotes' 
        ELSE tv.Upvotes::TEXT 
    END AS UpvotesStatus,
    CASE 
        WHEN r.ViewCount IN (0, NULL) THEN 'No Views' 
        ELSE r.ViewCount::TEXT 
    END AS ViewCountStatus
FROM 
    RankedPosts r
JOIN 
    TopUsers t ON r.PostRank = 1 AND r.PostId IN (SELECT p.PostId FROM Posts p WHERE p.OwnerUserId = t.Id)
LEFT JOIN 
    TotalVotes tv ON r.PostId = tv.PostId
WHERE 
    r.CreationDate >= NOW() - INTERVAL '3 months'
ORDER BY 
    t.Reputation DESC, r.CreationDate DESC
LIMIT 5;

-- additional complex conditions can be added for further specificity 
