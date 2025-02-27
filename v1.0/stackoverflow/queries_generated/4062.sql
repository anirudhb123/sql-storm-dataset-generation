WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(rp.Views) AS TotalViews,
        SUM(rp.Upvotes - rp.Downvotes) AS NetVotes,
        AVG(rp.Score) AS AverageScore,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 2) AS SilverBadges
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.TotalViews,
    up.NetVotes,
    up.AverageScore,
    COALESCE(up.GoldBadges, 0) AS GoldBadges,
    COALESCE(up.SilverBadges, 0) AS SilverBadges,
    COUNT(DISTINCT p.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenedPosts
FROM 
    UserPerformance up
LEFT JOIN 
    Posts p ON p.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    up.Reputation > (SELECT AVG(Reputation) FROM Users)
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, up.TotalPosts, up.TotalViews, up.NetVotes, up.AverageScore
ORDER BY 
    up.NetVotes DESC, up.TotalViews DESC
LIMIT 10;
