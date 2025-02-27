WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        rph.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title
),
*AggregatedPostLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM PostLinks pl
    GROUP BY pl.PostId
)

SELECT 
    ph.Title AS PostTitle,
    ph.CreationDate AS PostCreationDate,
    COALESCE(upp.BadgeCount, 0) AS UserBadgeCount,
    pcc.CommentCount AS TotalComments,
    pcc.AverageCommentScore AS AvgCommentScore,
    COALESCE(apl.RelatedPostCount, 0) AS TotalRelatedPosts,
    ph.Level AS PostLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS PostTags
FROM RecursivePostHierarchy ph
LEFT JOIN Users u ON ph.Id = u.Id  -- Assuming this correlates posts with their authors
LEFT JOIN UserWithBadges upp ON u.Id = upp.UserId
LEFT JOIN PostsWithComments pcc ON ph.Id = pcc.PostId
LEFT JOIN AggregatedPostLinks apl ON ph.Id = apl.PostId
LEFT JOIN LATERAL (
    SELECT 
        unnest(string_to_array(Substring(ph.Tags, 2, length(ph.Tags)-2), '>')) AS TagName
) t ON TRUE
WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
AND (pcc.CommentCount > 5 OR apl.RelatedPostCount > 2)
GROUP BY ph.Title, ph.CreationDate, upp.BadgeCount, pcc.CommentCount, pcc.AverageCommentScore, apl.RelatedPostCount, ph.Level
ORDER BY ph.CreationDate DESC, TotalComments DESC;
