
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        PostCount,
        CommentCount,
        BadgeCount,
        @Rank := @Rank + 1 AS Rank
    FROM 
        UserActivity, (SELECT @Rank := 0) AS r
    ORDER BY 
        Reputation DESC, PostCount DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBounties,
    tu.PostCount,
    tu.CommentCount,
    tu.BadgeCount,
    CASE 
        WHEN tu.Reputation < 100 THEN 'Novice'
        WHEN tu.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserTier,
    (SELECT COUNT(DISTINCT ph.Id) 
     FROM PostHistory ph 
     JOIN Posts pp ON ph.PostId = pp.Id 
     WHERE pp.OwnerUserId = tu.UserId AND ph.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)) AS RecentEdits,
    (SELECT GROUP_CONCAT(DISTINCT tg.TagName SEPARATOR ', ') 
     FROM Posts p 
     JOIN Tags tg ON p.Tags LIKE CONCAT('%', tg.TagName, '%') 
     WHERE p.OwnerUserId = tu.UserId) AS UserTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC, tu.PostCount DESC;
