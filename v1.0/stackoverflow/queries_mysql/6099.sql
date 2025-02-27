
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        @rank := IF(@prevPostTypeId = p.PostTypeId, @rank + 1, 1) AS Rank,
        @prevPostTypeId := p.PostTypeId,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @rank := 0, @prevPostTypeId := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR AND 
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId, p.PostTypeId
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    ue.PostCount,
    ue.TotalCommentScore,
    ue.TotalBountyAmount
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserEngagement ue ON up.Id = ue.UserId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, ue.TotalBountyAmount DESC;
