WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(ph.UserId IS NOT NULL), 0) AS TotalEdits
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id AND ph.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY 
        u.Id, u.DisplayName
), 
ActivitySummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalQuestions,
        ua.TotalBountyAmount,
        ua.TotalEdits,
        CASE 
            WHEN ua.TotalQuestions > 20 THEN 'Highly Active'
            WHEN ua.TotalQuestions BETWEEN 10 AND 20 THEN 'Moderately Active'
            ELSE 'Less Active'
        END AS ActivityLevel
    FROM 
        UserActivity ua
)
SELECT 
    ps.Title,
    ps.Score,
    ps.ViewCount,
    us.DisplayName,
    us.TotalQuestions,
    us.TotalBountyAmount,
    us.TotalEdits,
    us.ActivityLevel
FROM 
    RankedPosts ps
JOIN 
    ActivitySummary us ON ps.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = us.UserId)
WHERE 
    ps.RankPerUser <= 3
ORDER BY 
    ps.Score DESC, us.TotalQuestions DESC;
