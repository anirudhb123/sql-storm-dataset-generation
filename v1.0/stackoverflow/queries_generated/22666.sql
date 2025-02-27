WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM 
        Users u
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.Comment
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        (SELECT AVG(Score) FROM Posts p WHERE p.PostTypeId = rp.PostTypeId) AS AvgScore,
        CASE 
            WHEN rp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = rp.PostTypeId) THEN 'Above Average'
            WHEN rp.Score < (SELECT AVG(Score) FROM Posts WHERE PostTypeId = rp.PostTypeId) THEN 'Below Average'
            ELSE 'Average'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
        LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CloseCount,
    pm.AvgScore,
    pm.ScoreCategory,
    (SELECT STRING_AGG(pt.Name, ', ') 
     FROM PostTypes pt 
     WHERE pt.Id = pm.PostTypeId) AS PostType, 
    (SELECT STRING_AGG(DISTINCT ut.ReputationCategory, ', ')
     FROM Users u 
     JOIN UserReputation ut ON u.Id = pm.PostId 
     WHERE u.Id = pm.PostId) AS UserCategory,
    (SELECT COUNT(DISTINCT tag) 
     FROM PopularTags 
     WHERE tag IN (SELECT UNNEST(STRING_TO_ARRAY(pm.Tags, '><')))) AS PopularTagCount
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
