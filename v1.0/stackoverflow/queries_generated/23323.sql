WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
Stats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT cp.CommentId) AS CommentsPosted,
        MAX(p.LastActivityDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT c.Id AS CommentId, c.UserId 
         FROM Comments c 
         WHERE c.CreationDate >= NOW() - INTERVAL '1 year') AS cp ON cp.UserId = u.Id
    WHERE 
        u.Reputation > (
            SELECT 
                AVG(Reputation) 
            FROM 
                Users
        )
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    s.UserId,
    s.DisplayName,
    s.Reputation,
    s.GoldBadges,
    s.SilverBadges,
    s.BronzeBadges,
    r.CommentCount,
    CASE 
        WHEN r.AcceptedAnswerId IS NULL THEN 'No Accepted Answer' 
        ELSE 'Accepted Answer Exists' 
    END AS AnswerStatus,
    CASE 
        WHEN s.Reputation > 1000 THEN 
            'Highly reputable user' 
        ELSE 
            'Common user' 
    END AS UserReputationLabel
FROM 
    RankedPosts r
LEFT JOIN 
    Stats s ON r.OwnerUserId = s.UserId
WHERE 
    r.Rank = 1 
ORDER BY 
    r.ViewCount DESC NULLS LAST;

This SQL query performs the following operations:

1. **Common Table Expression (CTE)** `RankedPosts`: Retrieves posts created in the last year, counts comments, ranks posts for each user by creation date (latest first), and computes scores.

2. **Another CTE** `Stats`: Gathers user statistics, including the count of gold, silver, and bronze badges, total post count, and total comments posted in the last year, filtering users with above-average reputation.

3. **Main Query**: Joins the ranked posts with user stats and provides insight into the top-ranked post for users, along with additional labels based on the user's reputation and the status of the accepted answer.

4. **Complex Logic**: Utilizes COALESCE for handling NULL values, provides various labels based on conditions, and incorporates filtering based on average reputation.

5. **Outer Joins**: Demonstrates the relationships between posts, comments, users, and badges, even if some relationships may not exist.

This query is designed to benchmark performance by operating across multiple CTEs and leveraging window functions, correlated subqueries, and conditional expressions, which can push the limits of database optimization techniques.
