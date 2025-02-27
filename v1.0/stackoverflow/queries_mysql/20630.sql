
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) 
                  FROM Votes v 
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH)
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        tp.TagName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT pt.PostId, t.TagName, COUNT(t.TagName) AS TagCount
         FROM 
             (SELECT PostId, SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName 
              FROM Posts 
              JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
                    SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
              ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) pt
         JOIN 
             Tags t ON pt.TagName = t.TagName
         GROUP BY pt.PostId, t.TagName
         HAVING COUNT(t.TagName) > 2) tp ON rp.PostId = tp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.TagName,
    COUNT(t.PostId) AS PostCount,
    AVG(rp.ViewCount) AS AvgViewCount,
    SUM(rp.UpVoteCount - rp.DownVoteCount) AS NetVoteCount
FROM 
    TaggedPosts t
JOIN 
    RankedPosts rp ON t.PostId = rp.PostId
GROUP BY 
    t.TagName, rp.ViewCount, rp.UpVoteCount, rp.DownVoteCount
HAVING 
    AVG(rp.ViewCount) > 100
    AND COUNT(t.PostId) > 1
ORDER BY 
    NetVoteCount DESC
LIMIT 10;
