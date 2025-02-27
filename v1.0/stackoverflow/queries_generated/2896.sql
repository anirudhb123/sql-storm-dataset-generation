WITH RecentUsers AS (
    SELECT 
        Id, 
        DisplayName,
        COALESCE(Location, 'No Location') AS Location,
        Reputation,
        DENSE_RANK() OVER (ORDER BY CreationDate DESC) AS UserRank
    FROM Users
    WHERE Reputation > 1000
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagPostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN PostLinks pl ON pl.RelatedPostId = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '90 days'
    GROUP BY t.TagName
    ORDER BY TagPostCount DESC
    LIMIT 5
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Location,
    u.Reputation,
    ps.CommentCount,
    ps.Score,
    (SELECT STRING_AGG(pt.TagName, ', ') 
     FROM Tags pt 
     WHERE pt.Count > 100) AS PopularTags,
    (SELECT COUNT(*) FROM Votes v 
     WHERE v.UserId = u.Id AND v.CreationDate >= NOW() - INTERVAL '30 days') AS RecentVotes
FROM RecentUsers u
LEFT JOIN PostScores ps ON ps.ScoreRank <= 10
WHERE u.UserRank <= 50
ORDER BY u.Reputation DESC, ps.Score DESC
LIMIT 20;
