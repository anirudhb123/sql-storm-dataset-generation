
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RN = 1  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE((SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
               FROM Posts AS p2 
               JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p2.Tags, ',', numbers.n), ',', -1)) AS TagName 
                     FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                           UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                           UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
                     WHERE CHAR_LENGTH(p2.Tags) - CHAR_LENGTH(REPLACE(p2.Tags, ',', '')) >= numbers.n - 1) AS t
               WHERE p2.Id = rp.PostId 
               AND t.TagName IS NOT NULL), 
               'No Tags') AS Tags,
    COALESCE((SELECT COUNT(*) 
               FROM Comments c 
               WHERE c.PostId = rp.PostId), 
               0) AS CommentCount
FROM 
    RecentPosts rp
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
