WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS CloseReopenDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (12, 13)) AS DeleteUndeleteCount,
        AVG(EXTRACT(EPOCH FROM (ph.CreationDate - LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate))) / 60) AS AvgMinutesBetweenEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    ph.CloseReopenDate,
    ph.DeleteUndeleteCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.Title,
    CASE 
        WHEN rp.RankByType = 1 THEN 'Most Recent'
        WHEN rp.RankByType < 5 THEN 'Recently Popular'
        ELSE 'Less Active'
    END AS ActivityLevel,
    CASE 
        WHEN up.TotalPosts = 0 THEN NULL
        ELSE ROUND((CAST(up.GoldBadges AS FLOAT) / up.TotalPosts) * 100, 2)
    END AS GoldBadgePercentage,
    COALESCE(ph.AvgMinutesBetweenEdits, 0) AS AvgMinutesBetweenEdits
FROM 
    UserActivity up
LEFT JOIN 
    PostHistoryAnalysis ph ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id IN 
        (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 11) 
        ORDER BY CreationDate DESC LIMIT 1))
LEFT JOIN 
    RankedPosts rp ON up.TotalPosts > 0 AND rp.OwnerUserId = up.UserId
WHERE 
    up.TotalPosts > 0 AND 
    (up.GoldBadges IS NOT NULL OR up.SilverBadges IS NOT NULL)
ORDER BY 
    up.TotalPosts DESC, 
    rp.UpVoteCount DESC
LIMIT 100 OFFSET 0;
