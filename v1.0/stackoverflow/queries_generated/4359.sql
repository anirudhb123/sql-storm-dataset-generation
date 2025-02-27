WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        UserId,
        SUM(Reputation) AS TotalReputation
    FROM 
        Users
    GROUP BY 
        UserId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        ur.TotalReputation,
        CASE 
            WHEN rp.Score >= 100 THEN 'High'
            WHEN rp.Score >= 50 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.Rank,
    ps.CommentCount,
    ps.TotalReputation,
    ps.ScoreCategory,
    COALESCE(EXTRACT(EPOCH FROM (SELECT MAX(LastEditDate) FROM Posts WHERE Id = ps.PostId)), 0) AS LastEditUnixEpoch,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId IN (10, 11)) 
        THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostStatistics ps
ORDER BY 
    ps.Rank, ps.TotalReputation DESC
LIMIT 50;
