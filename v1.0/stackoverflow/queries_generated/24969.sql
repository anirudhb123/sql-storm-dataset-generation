WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotesCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        COALESCE(SUM(c.Id IS NOT NULL), 0) AS CommentCount,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (1, 2) THEN ph.Id END) AS HistoryCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY AVG(p.Score) DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.Title
),
CombinedSummary AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.AverageScore,
        ps.PostRank,
        us.UserRank,
        CASE 
            WHEN us.UserRank <= 10 THEN 'Top User'
            WHEN us.UserRank <= 25 THEN 'Moderate User'
            ELSE 'New User'
        END AS UserCategory
    FROM UserScoreSummary us
    LEFT JOIN PostSummary ps ON us.UserId = ps.OwnerUserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.Title,
    cs.CommentCount,
    cs.AverageScore,
    cs.UserCategory,
    CASE 
        WHEN cs.AverageScore IS NULL THEN 'No Posts'
        WHEN cs.AverageScore > 10 THEN 'Highly Rated'
        ELSE 'Moderately Rated'
    END AS PostRating,
    CASE 
        WHEN cs.CommentCount = 0 THEN 'No Comments'
        WHEN cs.CommentCount < 5 THEN 'Few Comments'
        ELSE 'Many Comments'
    END AS CommentStatus
FROM CombinedSummary cs
WHERE cs.UserCategory = 'Top User'
  OR cs.PostRank <= 3
ORDER BY cs.Reputation DESC, cs.AverageScore DESC;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        1 AS Level
    FROM Tags t
    WHERE t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id AS TagId,
        th.TagName,
        th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON th.TagId = t.Id
)
SELECT 
    th.TagName,
    th.Level,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
FROM TagHierarchy th
LEFT JOIN Posts p ON p.Tags LIKE '%' || th.TagName || '%'
GROUP BY th.TagName, th.Level
HAVING SUM(COALESCE(p.ViewCount, 0)) > 100
ORDER BY th.Level, TotalViews DESC;
