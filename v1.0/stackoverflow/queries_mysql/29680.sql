
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        p.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Tags, p.ViewCount
),
TagAnalysis AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS Tag,
        p.ViewCount,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes
    FROM 
        RecentPosts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t,
            (SELECT @row := 0) r) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
)
SELECT 
    Tag,
    COUNT(*) AS PostCount,
    AVG(ViewCount) AS AvgViewCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes
FROM 
    TagAnalysis
GROUP BY 
    Tag
ORDER BY 
    PostCount DESC
LIMIT 10;
