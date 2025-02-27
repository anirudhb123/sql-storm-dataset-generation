WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(NULLIF(SUM(b.Class = 1), 0), NULL) AS GoldBadges,  -- Gold badges with NULL logic
        COALESCE(NULLIF(SUM(b.Class = 2), 0), NULL) AS SilverBadges,
        COALESCE(NULLIF(SUM(b.Class = 3), 0), NULL) AS BronzeBadges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastActivity,
        STRING_AGG(ph.Comment, '; ') AS ActivityComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (SELECT MAX(CreationDate) - INTERVAL '30 days' FROM PostHistory)
    GROUP BY 
        ph.PostId, ph.UserId, ph.PostHistoryTypeId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(CASE WHEN rp.UserRank = 1 THEN 1 ELSE 0 END) AS TopPosts,
        SUM(DISTINCT pa.UserId) AS UniqueActivity Users -- Unique users who interacted with the post
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN 
        PostActivity pa ON pa.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
    WHERE 
        u.Reputation > 500  -- Arbitrary filter to include only high-reputation users
    GROUP BY 
        u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TopPosts,
    rp.Title,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.GoldBadges,
    rp.SilverBadges,
    rp.BronzeBadges,
    pa.LastActivity,
    pa.ActivityComments
FROM 
    UserPostSummary ups
LEFT JOIN 
    RankedPosts rp ON ups.TotalPosts > 0
LEFT JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    (rp.UpVotes IS NOT NULL AND rp.DownVotes IS NULL) -- Only posts that have been upvoted and not downvoted
    OR (ups.TopPosts > 2 AND rp.CommentCount > 5) -- Top posts with significant engagement
ORDER BY 
    ups.TopPosts DESC, rp.UpVotes DESC;
