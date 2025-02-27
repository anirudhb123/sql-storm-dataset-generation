
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    WHERE 
        TagCount > 10  
    ORDER BY 
        TagCount DESC
),
PostSummary AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes, 
        rp.DownVotes,
        tt.TagName
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%')
)
SELECT 
    Title,
    OwnerDisplayName,
    CommentCount,
    UpVotes,
    DownVotes,
    GROUP_CONCAT(TagName SEPARATOR ', ') AS Tags
FROM 
    PostSummary
GROUP BY 
    Title, OwnerDisplayName, CommentCount, UpVotes, DownVotes
ORDER BY 
    UpVotes DESC, CommentCount DESC;
