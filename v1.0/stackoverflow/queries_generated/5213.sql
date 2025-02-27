WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY u.Id
)
SELECT 
    u.DisplayName, 
    t.TotalScore, 
    t.TotalViews, 
    t.TotalUpVotes, 
    ARRAY_AGG(DISTINCT rp.Title) AS RecentPosts
FROM TopUsers t
JOIN Users u ON t.UserId = u.Id
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE t.UserRank <= 10
GROUP BY u.DisplayName, t.TotalScore, t.TotalViews, t.TotalUpVotes
ORDER BY t.TotalScore DESC;
