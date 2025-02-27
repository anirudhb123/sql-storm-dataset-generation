WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(vt.Score, 0)) AS TotalVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankByPosts,
        RANK() OVER (ORDER BY SUM(COALESCE(vt.Score, 0)) DESC) AS RankByVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    GROUP BY u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId AS CloserUserId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY ph.PostId, ph.UserId
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.TotalVotes,
        ua.RankByPosts,
        ua.RankByVotes,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount
    FROM UserActivity ua
    LEFT JOIN (
        SELECT 
            Closers.ClosedUserId,
            COUNT(DISTINCT cp.PostId) AS ClosedPostCount
        FROM (
            SELECT 
                DISTINCT ph.CloserUserId AS ClosedUserId,
                ph.PostId
            FROM ClosedPosts ph
        ) AS Closers
        GROUP BY Closers.ClosedUserId
    ) AS cp ON ua.UserId = cp.ClosedUserId
)
SELECT 
    ru.DisplayName,
    ru.PostCount,
    ru.TotalVotes,
    ru.ClosedPostCount,
    CASE 
        WHEN ru.RankByPosts = 1 THEN 'Top Poster'
        WHEN ru.RankByVotes = 1 THEN 'Top Voter'
        ELSE 'Regular User'
    END AS UserType
FROM RankedUsers ru
WHERE ru.ClosedPostCount > 0
ORDER BY ru.TotalVotes DESC, ru.PostCount DESC
LIMIT 10;

SELECT 
    DISTINCT p.Tags
FROM Posts p
WHERE p.ViewCount > 100 
  AND EXISTS (
      SELECT 1
      FROM Comments c
      WHERE c.PostId = p.Id
        AND c.CreationDate >= NOW() - INTERVAL '30 days'
        AND (
            c.Text ILIKE '%help%' OR 
            c.Text ILIKE '%please%'
        )
    )
ORDER BY p.ViewCount DESC;

SELECT *
FROM Users u
WHERE NOT EXISTS (
    SELECT 1 
    FROM Posts p 
    WHERE p.OwnerUserId = u.Id
) AND u.Reputation > 1000;

SELECT p.Title, COUNT(c.Id) AS CommentCount
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY p.Title
HAVING COUNT(c.Id) > 0
ORDER BY COUNT(c.Id) DESC;

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(u.Reputation) AS AverageUserReputation
FROM Posts p
JOIN PostTypes pt ON p.PostTypeId = pt.Id
JOIN Users u ON p.OwnerUserId = u.Id
WHERE p.CreationDate >= '2023-01-01 00:00:00'
GROUP BY pt.Name
ORDER BY TotalPosts DESC;
