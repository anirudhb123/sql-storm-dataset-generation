WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only posts with a positive score
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.CreationDate > NOW() - INTERVAL '1 MONTH' THEN 1 ELSE 0 END) AS RecentPosts,
        AVG(v.VoteTypeId) AS AvgVoteType -- Average of vote types on their posts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopCloseReasons AS (
    SELECT 
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close reason history
    GROUP BY 
        ph.Comment
    ORDER BY 
        CloseCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.PositivePosts,
    ua.RecentPosts,
    ub.BadgeCount,
    p.Title AS RecentPostTitle,
    p.CreationDate AS RecentPostDate,
    ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank,
    STRING_AGG(DISTINCT tr.CloseReason, ', ') AS TopCloseReasons
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.rn = 1 -- Most recent post
LEFT JOIN 
    TopCloseReasons tr ON 1=1 -- Cross join to get close reasons for everyone
WHERE 
    u.Reputation > 100 -- Only users with reputation greater than 100
GROUP BY 
    u.DisplayName, ua.TotalPosts, ua.PositivePosts, ua.RecentPosts, ub.BadgeCount, p.Title, p.CreationDate
ORDER BY 
    ua.TotalPosts DESC, UserRank;
