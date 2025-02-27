
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), ' ', -1) AS TagName
         FROM Posts p
         CROSS JOIN (SELECT a.N FROM (SELECT 1 AS N UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) a) n
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.N - 1) AS t
    GROUP BY 
        p.Id, t.TagName
),

TopPostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UserReputation,
        cp.LastClosedDate,
        GROUP_CONCAT(pt.TagName ORDER BY pt.TagName SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    WHERE 
        rp.RankScore <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.UserReputation, cp.LastClosedDate
)

SELECT 
    tps.*,
    CASE
        WHEN tps.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE
        WHEN tps.UserReputation IS NULL THEN 'No Reputation'
        WHEN tps.UserReputation < 1000 THEN 'Low Reputation'
        ELSE 'High Reputation'
    END AS ReputationCategory
FROM 
    TopPostStatistics tps
WHERE 
    tps.Tags IS NOT NULL
ORDER BY 
    tps.Score DESC, tps.CreationDate ASC
LIMIT 20;
