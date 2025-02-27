WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END), 0) AS TotalViews,
        COALESCE(SUM(pb.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(pb.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(pb.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges pb ON u.Id = pb.UserId
    GROUP BY 
        u.Id
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close action
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.AnswerCount,
    ups.TotalViews,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    cp.CloseReasons
FROM 
    UserPostStats ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.Id LIMIT 1)
LEFT JOIN 
    ClosedPostReasons cp ON rp.Id = cp.PostId
WHERE 
    ups.TotalViews > 100
ORDER BY 
    ups.TotalViews DESC, ups.AnswerCount DESC
FETCH FIRST 50 ROWS ONLY;
