
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.ViewCount > 0
), UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
), PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag_name
        FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_names ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    rp.ViewCount,
    pt.Tags,
    CASE 
        WHEN rp.RN = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId 
            AND ph.PostHistoryTypeId = 10
        ) THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.RN <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
