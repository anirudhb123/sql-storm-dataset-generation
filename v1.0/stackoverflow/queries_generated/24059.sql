WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(
            COUNT(DISTINCT c.Id), 0
        ) AS CommentCount,
        COALESCE(
            COUNT(DISTINCT v.Id), 0
        ) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),

HighScoringPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RecentPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts)  -- Posts above average score
),

UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

JoinedData AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(hp.PostCount, 0) AS HighScoringPostCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.HighestBadgeClass, 3) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS PostCount
        FROM 
            HighScoringPosts
        GROUP BY 
            OwnerUserId
    ) hp ON u.Id = hp.OwnerUserId
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
)

SELECT 
    jd.DisplayName,
    jd.Reputation,
    jd.Views,
    jd.HighScoringPostCount,
    jd.BadgeCount,
    jd.HighestBadgeClass,
    CASE 
        WHEN jd.HighestBadgeClass = 1 THEN 'Gold'
        WHEN jd.HighestBadgeClass = 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS BadgeLevel,
    CONCAT(jd.DisplayName, ' has created ', jd.HighScoringPostCount, ' high-scoring posts and holds ', jd.BadgeCount, ' badges.') AS UserSummary
FROM 
    JoinedData jd
WHERE 
    jd.Reputation > (SELECT AVG(Reputation) FROM Users)  -- Filter users with above-average reputation
ORDER BY 
    jd.HighScoringPostCount DESC, 
    jd.Reputation DESC;  -- Order by high-scoring posts and reputation
The above SQL query utilizes several advanced concepts:

1. **CTEs** (`RecentPosts`, `HighScoringPosts`, and `UserBadgeCounts`) to break down complex calculations into manageable parts.
2. **LEFT JOINs** for combining posts with their comments and votes, ensuring even posts without comments or votes are included.
3. **`COALESCE`** to handle potential `NULL` values gracefully.
4. **Window functions** to rank posts within partitions and calculate aggregates.
5. **Compound predicates** and calculations in the `SELECT` clause to derive additional insights from the data.
6. **`CASE` statements** to convert numeric badge classes into human-readable formats.
7. **String concatenation** for generating a user-friendly summary of each user's contributions.

These constructs collectively simulate an engaging and insightful analysis of users based on their contributions and reputations across high-scoring posts, combining both logical and technical SQL capabilities.
