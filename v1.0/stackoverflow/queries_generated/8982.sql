WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        us.UserId,
        us.DisplayName AS UserDisplayName,
        us.Reputation AS UserReputation,
        us.BadgeCount,
        us.TotalBounties
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.UserDisplayName,
    pd.UserReputation,
    pd.BadgeCount,
    pd.TotalBounties,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM 
    PostDetails pd
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON pd.PostId = c.PostId
ORDER BY 
    pd.CreationDate DESC;
