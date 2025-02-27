WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(v.VoteTypeId = 2) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
), RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        AVG(p.Score) AS AverageScore,
        COUNT(ph.Id) AS HistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
)
SELECT 
    ru.DisplayName,
    ru.Upvotes,
    ru.Downvotes,
    ru.PostCount,
    rpa.CommentCount,
    rpa.AverageScore,
    rpa.HistoryCount
FROM RankedUsers ru
JOIN RecentPostActivity rpa ON ru.UserId = rpa.OwnerUserId
WHERE ru.UserRank <= 10
ORDER BY ru.Upvotes DESC, rpa.AverageScore DESC;
