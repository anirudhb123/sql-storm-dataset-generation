
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 7 DAY
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        RecentPosts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(Tag) AS UsageCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    GROUP_CONCAT(tt.Tag ORDER BY tt.Tag SEPARATOR ', ') AS TopTags
FROM 
    RecentPosts rp
JOIN 
    TagStatistics tt ON FIND_IN_SET(tt.Tag, REPLACE(rp.Tags, '><', ',')) > 0
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerName, rp.CommentCount, rp.UpVotes, rp.DownVotes
ORDER BY 
    rp.CommentCount DESC, rp.UpVotes DESC;
