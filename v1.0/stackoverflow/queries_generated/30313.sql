WITH RecursiveTagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        1 AS Level
    FROM Tags t
    WHERE t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.Id = r.TagId
    WHERE r.Level < 5
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostOrder
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
    HAVING COUNT(DISTINCT p.Id) > 10
)
SELECT 
    ts.UserId,
    ts.DisplayName,
    ts.TotalPosts,
    ts.TotalScore,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    rt.TagName AS RelatedTags,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM TopUsers ts
LEFT JOIN PostSummary ps ON ts.Id = ps.OwnerName
LEFT JOIN PostLinks pl ON ps.PostId = pl.PostId
LEFT JOIN Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN Votes v ON ps.PostId = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart or BountyClose
LEFT JOIN RecursiveTagHierarchy rt ON t.Id = rt.TagId
WHERE ps.UserPostOrder = 1
GROUP BY ts.UserId, ts.DisplayName, ts.TotalPosts, ts.TotalScore, ps.PostId, ps.Title, ps.ViewCount, ps.AnswerCount, ps.CommentCount, ps.CreationDate, rt.TagName
ORDER BY TotalScore DESC, TotalPosts DESC
LIMIT 10;
