WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ur.Reputation,
        ur.TotalBounties,
        RANK() OVER (ORDER BY ur.Reputation + ur.TotalBounties DESC) AS UserRanking
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        u.Reputation > 100 -- Only consider high-reputation users
    ORDER BY 
        UserRanking
)
SELECT 
    p.Title,
    p.CreationDate,
    up.DisplayName AS UserDisplayName,
    up.Reputation,
    up.TotalBounties,
    rp.AnswerCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers up ON rp.OwnerUserId = up.Id
WHERE 
    rp.UserPostRank <= 5 -- Top 5 posts per user
    AND rp.AnswerCount > 0 -- Only include posts with answers
ORDER BY 
    p.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination
