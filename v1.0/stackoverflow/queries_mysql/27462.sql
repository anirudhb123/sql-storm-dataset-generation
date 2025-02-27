
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName
         FROM Posts p
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
               CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) + 1) t ON true
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
RecentPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        SUM(p.Score > 0) AS PositiveVotes,
        SUM(p.Score < 0) AS NegativeVotes,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.CreationDate) AS LastInteraction
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.CommentCount,
        rps.PositiveVotes,
        rps.NegativeVotes,
        rps.AvgViewCount,
        rps.LastInteraction,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        RecentPostStatistics rps ON rp.PostId = rps.PostId
    WHERE 
        rp.rn = 1 
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    Tags,
    CommentCount,
    PositiveVotes,
    NegativeVotes,
    AvgViewCount,
    LastInteraction,
    ScoreCategory
FROM 
    FinalResults
ORDER BY 
    LastInteraction DESC
LIMIT 100;
