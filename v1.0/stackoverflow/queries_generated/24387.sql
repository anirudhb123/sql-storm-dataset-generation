WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 
        END AS IsAccepted
    FROM Posts p
    WHERE p.PostTypeId = 2 -- Only Answers
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ua.TotalBounty,
    ua.AverageReputation,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViewCount,
    rp.CommentCount AS TopPostCommentCount,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM Tags tag 
     JOIN LATERAL (SELECT UNNEST(STRING_TO_ARRAY(rp.Tags, ',')) AS tagName) AS t ON t.tagName = tag.TagName) AS AssociatedTags
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.ScoreRank = 1
WHERE 
    (SELECT COUNT(*) FROM AcceptedAnswers aa WHERE aa.OwnerUserId = u.Id AND aa.IsAccepted = 1) > 0
    AND rp.RecentPostRank < 5
ORDER BY u.Reputation DESC NULLS LAST;
