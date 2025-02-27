WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Only count BountyStart and BountyClose votes
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.TotalBounty) AS BountyEarned,
    MAX(rp.CreationDate) AS LastPostDate,
    CASE 
        WHEN SUM(rp.Score) > 100 THEN 'Expert Contributor' 
        WHEN SUM(rp.Score) BETWEEN 50 AND 100 THEN 'Active Contributor' 
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 1000 -- Consider only high-reputation users
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalScore DESC;
