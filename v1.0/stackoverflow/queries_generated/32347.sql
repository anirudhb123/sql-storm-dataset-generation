WITH RecursivePostLinks AS (
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        pl.LinkTypeId, 
        1 AS Depth
    FROM PostLinks pl
    WHERE pl.LinkTypeId = 1
    UNION ALL
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        pl.LinkTypeId, 
        rpl.Depth + 1
    FROM PostLinks pl
    JOIN RecursivePostLinks rpl ON pl.PostId = rpl.RelatedPostId
    WHERE pl.LinkTypeId = 1 AND rpl.Depth < 5
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseOpenEvents
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
PostRanked AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.UpVotes,
        pm.DownVotes,
        pm.CommentCount,
        pm.CloseOpenEvents,
        ROW_NUMBER() OVER (ORDER BY pm.ViewCount DESC, pm.UpVotes DESC) AS PostRank
    FROM PostMetrics pm
)
SELECT 
    pr.PostId, 
    pr.Title, 
    pr.ViewCount, 
    pr.UpVotes, 
    pr.DownVotes, 
    pr.CommentCount,
    pr.CloseOpenEvents,
    COALESCE(pLinks.Count, 0) AS RelatedPostsCount,
    ubc.BadgeCount,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges
FROM PostRanked pr
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS Count
    FROM RecursivePostLinks
    GROUP BY PostId
) pLinks ON pr.PostId = pLinks.PostId
LEFT JOIN UserBadgeCounts ubc ON ubc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pr.PostId)
WHERE pr.PostRank <= 20
ORDER BY pr.PostRank;
