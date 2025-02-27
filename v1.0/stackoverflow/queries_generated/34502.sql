WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod votes
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.CreationDate,
        CASE 
            WHEN r.Score >= 100 THEN 'Gold'
            WHEN r.Score >= 50 THEN 'Silver'
            ELSE 'Bronze'
        END AS ScoreCategory,
        r.PostRank
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank = 1
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
UserPostCounts AS (
    SELECT 
        OwnerUserId AS UserId,
        COUNT(*) AS UserPostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    GROUP BY 
        OwnerUserId
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.Score,
    tp.ScoreCategory,
    up.UserPostCount,
    ub.BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.UserId = u.Id
LEFT JOIN 
    UserPostCounts up ON u.Id = up.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    up.UserPostCount IS NOT NULL OR ub.BadgeCount IS NOT NULL
ORDER BY 
    tp.Score DESC;

This query performs the following operations:

1. **CTEs** (Common Table Expressions):
    - `RankedPosts`: Calculates a rank for posts grouped by users and counts the number of upvotes on each post in the last year.
    - `TopPosts`: Filters to get only the top-ranked post for each user and assigns a score category based on the score of the post.
    - `UserBadges`: Counts badges held by users with a reputation greater than 1000.
    - `UserPostCounts`: Counts how many questions each user has posted.

2. **Main Select Query**: Joins all these CTEs to gather information about the user who created the top posts. It includes display names, titles of the top posts, score categories, total post counts, and badge counts, with the results ordered by score in descending order, filtering out users with no posts and no badges. 

3. Implements **LEFT JOINs** and aggregates while using window functions (e.g., `ROW_NUMBER()`) for ranking posts and handling NULL logic through `WHERE` clauses.

This structure allows for complex analytics and provides a lot of insight into user engagement and post performance on the platform.
