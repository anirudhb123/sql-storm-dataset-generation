WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,        -- Total UpVotes
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,     -- Total DownVotes
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
        SUM(rp.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts rp ON rp.PostId = p.Id
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    SUM(b.GoldBadges) AS TotalGoldBadges,
    SUM(b.SilverBadges) AS TotalSilverBadges,
    SUM(b.BronzeBadges) AS TotalBronzeBadges,
    AVG(rp.TotalUpVotes - rp.TotalDownVotes) AS AverageVoteDifference,
    AVG(rp.Score) AS AveragePostScore,
    COUNT(DISTINCT rp.PostId) AS TotalUniquePosts,
    COUNT(DISTINCT CASE WHEN rp.CommentCount > 0 THEN rp.PostId END) AS PostsWithComments,
    SUM(CASE WHEN rp.TotalBounty > 0 THEN 1 ELSE 0 END) AS PostsWithBounty
FROM 
    TopUsers tu
LEFT JOIN 
    BadgesSummary b ON tu.UserId = b.UserId
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = tu.UserId
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.PostCount
ORDER BY 
    tu.Reputation DESC, TotalPostScore DESC NULLS LAST
LIMIT 
    10;
