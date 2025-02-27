WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(vs.VoteScore, 0)) AS TotalScore, 
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        ARRAY_AGG(DISTINCT b.Name) AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            Vote.UserId,
            COUNT(CASE WHEN Vote.VoteTypeId = 2 THEN 1 END) AS VoteScore
        FROM 
            Votes Vote
        GROUP BY 
            Vote.UserId
    ) vs ON u.Id = vs.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.BadgeCount,
        us.Badges,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC, us.BadgeCount DESC) AS Ranking
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    u.DisplayName,
    u.TotalPosts AS UserPostCount,
    u.TotalScore AS UserScore,
    u.BadgeCount AS UserBadgeCount,
    u.Badges AS UserBadges,
    COALESCE(NULLIF(rp.AcceptedAnswerId, -1), 0) AS EffectiveAcceptedAnswerId,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11)
            ) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RecentPosts rp
JOIN 
    TopUsers u ON rp.OwnerUserId = u.UserId
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;

### Explanation:
- **CTE (Common Table Expressions)**:
  - `RecentPosts`: Filters posts created in the last 30 days and assigns a rank to each post per user by posting date.
  - `UserStats`: Aggregates user statistics, counting total posts, total score from votes, and badges received.
  - `TopUsers`: Ranks users based on total scores and badge counts, filtering out those with no posts.

- **Main Selection**: Combines recent posts with the top users based on user ID. It includes:
  - Extracted useful fields from posts and combined user statistics.
  - Calculates `EffectiveAcceptedAnswerId`, considering it might be `-1`.
  - Checks the status of posts to assess if they are 'Closed' or 'Open'.

- **NULL Logic**: The use of `COALESCE` and `NULLIF` ensures that if `AcceptedAnswerId` is `-1`, it gets treated correctly in the absence of a valid answer.

- **Case Logic**: A `CASE` statement determines whether a post is "Closed" or "Open" based on the `PostHistory` table's data.

- **Complicated Expressions**: The ranking logic in both user and post selection adds a layer of complexity, allowing for intricate performance measures that are reflective of the activity and achievements in the StackOverflow schema.
