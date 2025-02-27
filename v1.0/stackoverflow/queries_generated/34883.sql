WITH RECURSIVE UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
UserVotes AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
    GROUP BY p.Id
),
PostSummaries AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Score,
        pa.ViewCount,
        pa.CommentCount,
        pa.AverageBounty,
        ROW_NUMBER() OVER (ORDER BY pa.Score DESC) AS PostRank
    FROM PostAnalytics pa
    WHERE pa.ViewCount > 100 -- Only include popular posts
),
UserSummary AS (
    SELECT 
        ub.UserId,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        uv.UpVotes,
        uv.DownVotes,
        uv.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY ub.TotalBadges DESC, uv.UpVotes DESC) AS UserRank
    FROM UserBadges ub
    LEFT JOIN UserVotes uv ON ub.UserId = uv.UserId
)
SELECT 
    us.UserId,
    u.DisplayName,
    us.TotalBadges,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.UpVotes,
    us.DownVotes,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ps.CommentCount,
    ps.AverageBounty
FROM UserSummary us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN PostSummaries ps ON us.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = (
        SELECT PostId 
        FROM PostLinks 
        WHERE RelatedPostId = ps.PostId 
        LIMIT 1
    )
    LIMIT 1
)
WHERE us.UserRank <= 10 AND (ps.PostRank IS NULL OR ps.PostRank <= 5)
ORDER BY us.UserRank, ps.PostScore DESC;
