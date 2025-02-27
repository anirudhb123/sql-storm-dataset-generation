
WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
), user_activity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < CAST(DATEADD(MONTH, -1, '2024-10-01') AS DATE)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalScore,
    ua.PostCount,
    ua.BadgeCount,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.CommentCount,
    rp.AverageBounty
FROM 
    user_activity ua
JOIN 
    ranked_posts rp ON ua.UserId = rp.OwnerUserId
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.TotalScore DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
