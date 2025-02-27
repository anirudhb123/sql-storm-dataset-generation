WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5 AND SUM(Score) > 100
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(tp.PostCount, 0) AS PostCount,
        COALESCE(tp.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        (SELECT 
            UserId, COUNT(*) AS BadgeCount 
         FROM 
            Badges 
         GROUP BY 
            UserId) b ON u.Id = b.UserId
    LEFT JOIN 
        TopUsers tp ON u.Id = tp.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.PostCount,
    us.TotalScore,
    RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
FROM 
    UserStatistics us
WHERE 
    us.PostCount > 0
ORDER BY 
    ScoreRank,
    us.BadgeCount DESC;

-- Let's add some bizarre logic to see users with missing posts but having badges
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    (SELECT 
        UserId, COUNT(*) AS BadgeCount 
     FROM 
        Badges 
     GROUP BY 
        UserId) b ON u.Id = b.UserId
WHERE 
    NOT EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id)
    AND COALESCE(b.BadgeCount, 0) > 0
ORDER BY 
    BadgeCount DESC
FETCH FIRST 5 ROWS ONLY;
