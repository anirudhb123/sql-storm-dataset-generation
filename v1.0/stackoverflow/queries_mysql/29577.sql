
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ps.Name AS PostType,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS RecentVoteRank
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes ps ON p.PostTypeId = ps.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t 
    ON TRUE
    WHERE 
        p.CreationDate > DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
        AND p.ViewCount > 100
),

AggregatedPostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        MIN(rp.CreationDate) AS FirstSeen,
        MAX(rp.CreationDate) AS LastActive,
        GROUP_CONCAT(DISTINCT rp.TagName ORDER BY rp.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.RecentVoteRank = 1
    GROUP BY 
        rp.PostId, rp.Title
)

SELECT 
    apm.PostId,
    apm.Title,
    apm.VoteCount,
    apm.UpvoteCount,
    apm.DownvoteCount,
    apm.FirstSeen,
    apm.LastActive,
    apm.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = apm.PostId) AS CommentCount
FROM 
    AggregatedPostMetrics apm
ORDER BY 
    apm.VoteCount DESC, apm.LastActive DESC
LIMIT 100;
