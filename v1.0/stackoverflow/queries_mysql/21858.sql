
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(badges.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) badges ON u.Id = badges.UserId
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.PostCount,
        ps.TotalScore,
        ps.AvgViewCount,
        @row_number := IF(@prev_user = ur.UserId, @row_number + 1, 1) AS rn,
        @prev_user := ur.UserId
    FROM 
        UserReputation ur
    JOIN 
        PostSummary ps ON ur.UserId = ps.OwnerUserId,
        (SELECT @row_number := 0, @prev_user := NULL) AS vars
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.PostCount,
    au.TotalScore,
    au.AvgViewCount,
    CASE 
        WHEN au.Reputation > 1000 THEN 'High Reputation'
        WHEN au.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationLevel,
    COALESCE((
        SELECT GROUP_CONCAT(DISTINCT tag.TagName SEPARATOR ', ') 
        FROM Tags tag
        JOIN Posts post ON tag.WikiPostId = post.Id
        WHERE post.OwnerUserId = au.UserId
    ), 'No Tags') AS AssociatedTags,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v
            WHERE v.UserId = au.UserId
            AND v.VoteTypeId = 2
        ) THEN 'Has Upvotes'
        ELSE 'No Upvotes'
    END AS UpvoteStatus
FROM 
    ActiveUsers au
WHERE 
    au.rn = 1
ORDER BY 
    au.TotalScore DESC, 
    au.Reputation DESC
LIMIT 10;
