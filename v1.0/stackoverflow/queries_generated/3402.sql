WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        us.DisplayName,
        us.Reputation,
        us.TotalBounties,
        us.TotalPosts,
        COALESCE(cc.CommentCount, 0) AS TotalComments,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 'No Views'
            WHEN rp.ViewCount > 1000 THEN 'High Engagement'
            ELSE 'Moderate Engagement' 
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        CommentCounts cc ON rp.PostId = cc.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.DisplayName,
    pd.Reputation,
    pd.TotalBounties,
    pd.TotalPosts,
    pd.TotalComments,
    pd.EngagementLevel
FROM 
    PostDetails pd
WHERE 
    pd.UserPostRank = 1
ORDER BY 
    pd.Score DESC, pd.TotalComments DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
