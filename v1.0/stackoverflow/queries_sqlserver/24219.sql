
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT ph.PostId), 0) AS PostCount,
        MIN(u.CreationDate) OVER (PARTITION BY u.Id) AS FirstActivity
    FROM Users u
    LEFT JOIN Votes vote ON u.Id = vote.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
), 
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        DATEDIFF(hour, p.CreationDate, '2024-10-01 12:34:56') AS AgeInHours,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), 
TrendingPosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.ViewCount,
        (ap.CommentCount * 0.5 + 
         ISNULL(NULLIF(ap.ViewCount / NULLIF(DATEDIFF(second, ap.CreationDate, '2024-10-01 12:34:56') / 3600.0, 0), 1), 0) * 0.5) AS EngagementScore
    FROM ActivePosts ap
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    tp.Title,
    tp.ViewCount,
    tp.EngagementScore,
    CASE 
        WHEN us.FirstActivity IS NOT NULL AND us.FirstActivity < DATEADD(year, -1, '2024-10-01 12:34:56') THEN 'Veteran'
        WHEN us.Reputation < 100 THEN 'Newbie'
        ELSE 'Experienced'
    END AS UserTier
FROM UserStatistics us
LEFT JOIN TrendingPosts tp ON us.PostCount > 5
WHERE us.Reputation > 100 AND tp.EngagementScore > 1
ORDER BY tp.EngagementScore DESC, us.Reputation DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
