WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostCommentsSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
PostScores AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        COALESCE(ps.CommentCount, 0) AS TotalComments,
        COALESCE(ps.Comments, '') AS CommentsText,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS Rank
    FROM RecursivePosts rp
    LEFT JOIN PostCommentsSummary ps ON rp.Id = ps.PostId
),
UserRanking AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalViews,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        ua.TotalBadges,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS PostRank
    FROM UserActivity ua
)
SELECT 
    ur.DisplayName AS User,
    ur.TotalPosts,
    ur.TotalViews,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ur.TotalBadges,
    ps.Title AS TopPost,
    ps.TotalComments,
    ps.CommentsText,
    ps.Rank AS PostScoreRank
FROM UserRanking ur
JOIN PostScores ps ON ur.UserId = ps.OwnerUserId
WHERE ur.TotalPosts > 0
ORDER BY ur.PostRank, ps.Rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
