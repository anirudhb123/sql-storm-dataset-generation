WITH RecursiveTagDepth AS (
    SELECT Id, TagName, 1 AS Depth
    FROM Tags
    WHERE Count > 100  -- Only select tags with significant usage
    UNION ALL
    SELECT t.Id, t.TagName, rd.Depth + 1
    FROM Tags t
    JOIN RecursiveTagDepth rd ON t.Id = rd.ExcerptPostId  -- Join to increase depth
),
UserBadges AS (
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
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.ViewCount IS NOT NULL AND p.ViewCount > 1000  -- Filter for popular posts
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(v.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(v.DownvoteCount, 0) AS DownvoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(BadgeCounts.GoldBadges, 0) AS GoldBadges,
        COALESCE(BadgeCounts.SilverBadges, 0) AS SilverBadges,
        COALESCE(BadgeCounts.BronzeBadges, 0) AS BronzeBadges
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN UserBadges BadgeCounts ON p.OwnerUserId = BadgeCounts.UserId
)
SELECT 
    pa.PostId,
    pa.UpvoteCount,
    pa.DownvoteCount,
    pa.CommentCount,
    u.DisplayName,
    t.TagName,
    rd.Depth AS TagDepth
FROM PostAnalytics pa
JOIN Users u ON pa.OwnerUserId = u.Id
JOIN Posts p ON pa.PostId = p.Id
JOIN PostLinks pl ON pl.PostId = p.Id
JOIN Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN RecursiveTagDepth rd ON t.Id = rd.Id
WHERE 
    pa.UpvoteCount > 10 AND
    pa.CommentCount > 0 AND
    (pa.GoldBadges > 0 OR pa.SilverBadges > 0)
ORDER BY 
    pa.UpvoteCount DESC, 
    pa.CommentCount DESC;
