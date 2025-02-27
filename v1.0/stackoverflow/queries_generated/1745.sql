WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ua.QuestionCount,
    ua.TotalBounties,
    rp.Title AS MostRecentPostTitle,
    rp.Score
FROM 
    Users u
LEFT JOIN 
    UserAggregates ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    ua.QuestionCount DESC, 
    ua.TotalBounties DESC
LIMIT 10;
