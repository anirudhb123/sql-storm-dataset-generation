WITH RECURSIVE UserPostCounts AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        RANK() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM UserPostCounts
    WHERE TotalPosts > 10
)

SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    pm.PostId,
    pm.Title AS RecentPostTitle,
    pm.CreationDate AS RecentPostDate,
    pm.Score AS RecentPostScore,
    pm.ViewCount AS RecentPostViewCount,
    pm.CommentCount AS RecentPostCommentCount
FROM TopUsers u
JOIN PostMetrics pm ON u.UserId = pm.OwnerUserId
WHERE u.UserRank <= 10
ORDER BY u.TotalPosts DESC, pm.RecentPostRank
LIMIT 10;

-- An additional fragment for testing performance
SELECT
    COUNT(*) AS VoteCount,
    AVG(v.BountyAmount) AS AverageBounty
FROM Votes v
JOIN Posts p ON v.PostId = p.Id
WHERE v.CreationDate > NOW() - INTERVAL '6 MONTHS'
  AND EXISTS (
      SELECT 1
      FROM UserPostCounts upc
      WHERE upc.TotalPosts > 5
      AND upc.UserId = p.OwnerUserId
  );
