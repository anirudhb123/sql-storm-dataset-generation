WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
),
UserEngagements AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Score,
        pv.ViewCount,
        u.TotalBounty,
        u.TotalComments,
        u.TotalBadges,
        u.AvgReputation,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId), 0) AS CommentCount,
        (SELECT AVG(s.Score) FROM RankedPosts s WHERE s.PostId <> p.PostId AND s.PostTypeId = p.PostTypeId) AS AvgScoreRelated,
        CASE 
            WHEN p.CreationDate < NOW() - INTERVAL '90 days' THEN 'Old'
            WHEN p.CreationDate >= NOW() - INTERVAL '90 days' AND p.CreationDate < NOW() - INTERVAL '30 days' THEN 'Recent'
            ELSE 'New'
        END AS PostAgeClass
    FROM 
        RankedPosts p
    JOIN 
        UserEngagements u ON p.PostId = (SELECT ps.PostId FROM Posts ps WHERE ps.OwnerUserId = u.UserId LIMIT 1)
    LEFT JOIN 
        Posts pv ON pv.Id = p.PostId
)
SELECT 
    ps.PostId,
    ps.Score,
    ps.ViewCount,
    ps.TotalBounty,
    ps.TotalComments,
    ps.AvgReputation,
    ps.CommentCount,
    ps.AvgScoreRelated,
    ps.PostAgeClass
FROM 
    PostStatistics ps
WHERE 
    ps.TotalComments > 5
    OR (ps.PostTypeId = 1 AND ps.Score >= 10)
ORDER BY 
    ps.TotalBounty DESC, 
    ps.AvgReputation DESC;
