WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LastAccessDate,
        WebsiteUrl,
        Location,
        AboutMe,
        Views,
        UpVotes,
        DownVotes,
        ProfileImageUrl,
        EmailHash,
        AccountId,
        0 AS level
    FROM Users
    WHERE Reputation >= 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        u.WebsiteUrl,
        u.Location,
        u.AboutMe,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.ProfileImageUrl,
        u.EmailHash,
        u.AccountId,
        ur.level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation < ur.Reputation
    WHERE ur.level < 3
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.ViewCount > 100
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY v.PostId
)

SELECT 
    u.DisplayName,
    p.Title,
    p.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
    COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
    COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
    COALESCE(NULLIF(AVG(DATEDIFF(NOW(), p.CreationDate)), 0), 1) AS AveragePostAge
FROM UserReputation u
JOIN TopPosts p ON u.Id = p.OwnerUserId
LEFT JOIN PostComments pc ON p.Id = pc.PostId
LEFT JOIN RecentVotes rv ON p.Id = rv.PostId
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE p.rn = 1
GROUP BY u.DisplayName, p.Title, p.ViewCount, rv.UpVotes, rv.DownVotes
ORDER BY p.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;

This SQL query performs the following operations:
- It defines a recursive Common Table Expression (CTE) `UserReputation` to find users with a reputation of 1000 or higher, and it continues to find users with lesser reputations up to 3 levels deep.
- It creates another CTE `TopPosts` that selects the top posts authored by the users with the highest view counts and ranks them.
- The `PostComments` CTE calculates the number of comments for each post.
- The `RecentVotes` CTE aggregates votes from the last 30 days for posts with recent activity.
- Finally, the main query selects the top 10 authors with the most popular posts, aggregating various metrics including comment counts, upvotes, downvotes, badge counts, and calculating an average post age.
