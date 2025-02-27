WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 1
   
    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rt.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTags rt ON t.Id = rt.ExcerptPostId
),
PostRanking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(bc.BadgeCount, 0) AS TotalBadges,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
    SUM(pc.CommentCount) AS TotalComments,
    SUM(ua.Upvotes) AS TotalUpvotes,
    SUM(ua.Downvotes) AS TotalDownvotes,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT rt.Id) AS TotalTags
FROM Users u
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostComments pc ON p.Id = pc.PostId
LEFT JOIN BadgeCounts bc ON u.Id = bc.UserId
LEFT JOIN RecursiveTags rt ON rt.Id IN (SELECT unnest(string_to_array(p.Tags, '>')))
WHERE u.Reputation > 1000
GROUP BY u.Id, u.DisplayName, u.Reputation, bc.BadgeCount, bc.GoldBadges, bc.SilverBadges, bc.BronzeBadges
ORDER BY u.Reputation DESC, TotalPosts DESC
LIMIT 100;
