WITH UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS IsAcceptedAnswer,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC NULLS LAST) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
TagSummary AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostsCount,
        STRING_AGG(DISTINCT p.Title) AS PostTitles
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY t.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalBounties,
    ups.UserRank,
    pa.PostId,
    pa.Title AS PostTitle,
    pa.CreationDate,
    pa.ViewCount,
    pa.IsAcceptedAnswer,
    pa.PostRank,
    pa.CommentCount,
    ts.TagId,
    ts.TagName,
    ts.PostsCount,
    ts.ClosedPostsCount,
    ts.PostTitles
FROM UserPostSummary ups
JOIN PostActivity pa ON ups.UserId IN (
    SELECT OwnerUserId 
    FROM Posts WHERE CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
LEFT JOIN TagSummary ts ON ts.PostsCount > 0
WHERE ups.TotalPosts > 0
ORDER BY ups.UserRank, pa.ViewCount DESC
LIMIT 100;
