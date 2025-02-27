
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM Posts p
    WHERE p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Location IS NULL THEN 'Unknown Location' 
            ELSE u.Location 
        END AS UserLocation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(b.Name, 'No Badges') AS BadgeName,
        COALESCE((SELECT COUNT(*) 
                  FROM Posts p 
                  WHERE p.OwnerUserId = u.Id), 0) AS PostCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId AND b.Class = 1
    WHERE u.Reputation > 100
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.UserLocation,
    COUNT(DISTINCT rp.PostId) AS PostCount,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.Score) AS AverageScore,
    SUM(rp.Upvotes) AS TotalUpvotes,
    SUM(rp.Downvotes) AS TotalDownvotes,
    MAX(CASE WHEN rp.Rank = 1 THEN rp.CreationDate END) AS MostRecentPostDate,
    STRING_AGG(DISTINCT COALESCE(b.BadgeName, 'No Badges'), ', ') AS Badges
FROM ActiveUsers au
LEFT JOIN RankedPosts rp ON au.UserId = rp.OwnerUserId
LEFT JOIN Badges b ON au.UserId = b.UserId
GROUP BY au.UserId, au.DisplayName, au.UserLocation
HAVING COUNT(DISTINCT rp.PostId) > 0
ORDER BY TotalViews DESC, AverageScore DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
