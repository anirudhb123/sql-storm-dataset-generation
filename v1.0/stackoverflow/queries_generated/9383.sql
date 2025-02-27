WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS Count
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) c ON p.Id = c.ParentId
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalCommentScore,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.TotalBadges,
    COUNT(ps.PostId) AS UserPostCount,
    SUM(ps.ViewCount) AS UserTotalViews,
    SUM(ps.Score) AS UserTotalScore,
    SUM(ps.CommentCount) AS UserTotalComments,
    STRING_AGG(DISTINCT ps.Title, '; ') AS UserPostTitles
FROM UserActivity ua
LEFT JOIN PostStats ps ON ua.UserId = ps.OwnerUserId
GROUP BY ua.UserId, ua.DisplayName
ORDER BY UserTotalScore DESC, UserTotalViews DESC;
