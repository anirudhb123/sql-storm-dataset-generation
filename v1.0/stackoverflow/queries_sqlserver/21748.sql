
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
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
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
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserActivity
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
     WHERE pp.OwnerUserId = tu.UserId AND ph.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')) AS RecentEdits,
    (SELECT STRING_AGG(DISTINCT tg.TagName, ', ') 
     FROM Posts p 
     JOIN Tags tg ON p.Tags LIKE '%' + tg.TagName + '%' 
     WHERE p.OwnerUserId = tu.UserId) AS UserTags
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC, tu.PostCount DESC;
