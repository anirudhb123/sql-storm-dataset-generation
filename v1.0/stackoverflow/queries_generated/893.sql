WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(p.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
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
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        uc.UserId,
        uc.DisplayName,
        uc.Reputation,
        uc.PostCount,
        uc.TotalViews,
        uc.TotalUpVotes,
        uc.TotalDownVotes,
        COALESCE(cc.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserStats uc ON rp.OwnerUserId = uc.UserId
    LEFT JOIN 
        CommentCounts cc ON rp.PostId = cc.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.DisplayName,
    ps.Reputation,
    ps.PostCount,
    ps.TotalViews,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    CASE 
        WHEN ps.Reputation > 1000 THEN 'High Reputation'
        WHEN ps.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation' 
    END AS ReputationCategory
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 10
ORDER BY 
    ps.Score DESC, 
    ps.TotalViews DESC
FETCH FIRST 50 ROWS ONLY;
