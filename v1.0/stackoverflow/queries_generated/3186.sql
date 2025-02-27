WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ActiveUserPosts AS (
    SELECT 
        DISTINCT p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.TotalBounty,
    up.PostCount,
    up.TotalCommentScore,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = ur.UserId AND PostTypeId = 2) AS AnswerCount
FROM 
    UserReputation ur
LEFT JOIN 
    ActiveUserPosts up ON ur.UserId = up.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId AND rp.Rank = 1 
WHERE 
    ur.Reputation > 1000
ORDER BY 
    ur.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
