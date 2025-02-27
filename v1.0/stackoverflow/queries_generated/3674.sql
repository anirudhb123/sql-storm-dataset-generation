WITH RecentUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS RowNum
    FROM Users
    WHERE LastAccessDate >= NOW() - INTERVAL '1 year'
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '6 months'
    AND p.Score > 0
    GROUP BY p.Id
    HAVING COUNT(c.Id) > 5
),
TopTags AS (
    SELECT 
        Tags.TagName,
        COUNT(p.Id) AS PostCount
    FROM Posts p
    JOIN Tags ON Tags.Id = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY Tags.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    r.PostCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    b.BadgeNames,
    a.CommentCount
FROM RecentUsers u
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount
    FROM Posts
    WHERE CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY OwnerUserId
) r ON u.Id = r.OwnerUserId
LEFT JOIN UserBadges b ON u.Id = b.UserId
LEFT JOIN ActivePosts a ON u.Id = a.OwnerUserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND u.Id IN (SELECT UserId FROM Badges WHERE Class = 1)
ORDER BY u.Reputation DESC, a.CommentCount DESC NULLS LAST
LIMIT 50;
