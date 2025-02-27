WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserRanks AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(bp.TotalBounties, 0)) AS TotalBountiesReceived,
        AVG(CASE WHEN bp.Rank IS NOT NULL THEN 1 ELSE 0 END) AS AvgPostQuality
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts bp ON u.Id = bp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    ur.TotalBountiesReceived,
    ur.AvgPostQuality
FROM 
    UserRanks ur
WHERE 
    ur.QuestionCount > 0
ORDER BY 
    ur.TotalBountiesReceived DESC, ur.QuestionCount DESC, ur.Reputation DESC
LIMIT 10;
