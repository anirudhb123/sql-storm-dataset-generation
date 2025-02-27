WITH RecursiveTagHierarchy AS (
    -- Recursive CTE to get tag hierarchy if needed (for demonstration, assuming Tags could have child tags)
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
    WHERE IsRequired = 1
    
    UNION ALL
    
    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rth ON t.ExcerptPostId = rth.Id
),
UserBadges AS (
    -- CTE to aggregate users' badges by types
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostsWithComments AS (
    -- CTE with posts that have comments and their latest comments
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        MAX(c.CreationDate) AS LatestCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
UserReputation AS (
    -- Calculation of average reputation per tag for all users who contributed posts
    SELECT 
        t.TagName,
        AVG(u.Reputation) AS AvgReputation
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN LATERAL unnest(string_to_array(Tags, '>')) AS tagName
    JOIN Tags t ON t.TagName = tagName
    GROUP BY t.TagName
)
SELECT 
    th.TagName,
    th.Count AS TagCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    SUM(pwc.LatestCommentDate IS NOT NULL) AS PostsWithComments,
    ur.AvgReputation
FROM Tags th
LEFT JOIN UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || th.TagName || '%')
LEFT JOIN PostsWithComments pwc ON pwc.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || th.TagName || '%')
LEFT JOIN UserReputation ur ON ur.TagName = th.TagName
WHERE th.Count > 5
GROUP BY th.TagName, th.Count, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, ur.AvgReputation
ORDER BY TagCount DESC, AvgReputation DESC;
