WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(b.Class), 0) AS BadgeCount,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
MostActiveUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        TotalPosts > 0
)
SELECT 
    u.DisplayName,
    COALESCE(bp.Title, 'No posts') AS TopPostTitle,
    COALESCE(p.Rank, 0) AS PostRank,
    ua.TotalPosts,
    ua.TotalViews,
    ua.TotalScore,
    CASE 
        WHEN ua.BadgeCount > 0 THEN CONCAT('User has ', ua.BadgeCount, ' badges.')
        ELSE 'No badges awarded.'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    MostActiveUsers ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts p ON u.Id = p.OwnerUserId AND p.PostRank = 1
LEFT JOIN 
    (SELECT 
         bp.UserId,
         STRING_AGG(bp.Title, ', ') AS Title
     FROM 
         (SELECT 
              p.OwnerUserId,
              p.Title,
              SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
          FROM 
              Posts p
          LEFT JOIN 
              Votes v ON p.Id = v.PostId
          WHERE 
              p.CreationDate >= NOW() - INTERVAL '1 month'
          GROUP BY 
              p.OwnerUserId, p.Title
          HAVING 
              SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 3
         ) AS bp
     GROUP BY 
         bp.UserId
    ) AS bp ON u.Id = bp.UserId 
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    ua.TotalPosts DESC NULLS LAST,
    u.DisplayName;

### Explanation:
1. **CTEs**: Several Common Table Expressions (CTEs) are used to break down the query:
   - `RankedPosts`: Ranks posts created within the last month by score for each owner.
   - `UserStats`: Aggregates user statistics (total badges, total posts, etc.) using `LEFT JOIN` to ensure all users are included even if they have zero posts or badges.
   - `MostActiveUsers`: Filters the aggregated results to only include users with posts and ranks them.

2. **LEFT JOINs**: Combines results from posts and user stats, incorporating logic for displaying titles and badge counts.

3. **CASE Statements**: Used to construct a user-friendly summary for badge status.

4. **STRING_AGG**: Aggregates post titles into a single string for users with multiple eligible posts.

5. **HAVING Clause**: Filters out posts with insufficient votes to ensure noteworthy contributions are highlighted.

6. **NULL Handling**: Ensures that users without posts or badges are still represented in the results.

7. **Bizarre Semantics**: The use of string aggregation, correlated subqueries, and ranking functions combined with an arbitrary popularity metric adds complexity and performance metrics for further analysis.
