
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
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
        p.CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags, p.ViewCount
),
TagAnalysis AS (
    SELECT 
        value AS Tag,
        p.ViewCount,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes
    FROM 
        RecentPosts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') 
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
