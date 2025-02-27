
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(v.Id) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag 
         FROM Posts p
         INNER JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag 
    ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Owner,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.Tags
FROM 
    RecentPosts rp
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC
LIMIT 
    10;
