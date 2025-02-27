WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.AvgReputation,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.RelatedPostCount,
    CASE 
        WHEN ps.PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    UserStats us
LEFT JOIN 
    PostDetails ps ON us.UserId = ps.OwnerUserId
WHERE 
    us.BadgeCount > 5 
ORDER BY 
    us.AvgReputation DESC, ps.Score DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
