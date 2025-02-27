
WITH StringBenchmark AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        ph.UserDisplayName AS EditedBy,
        ph.CreationDate AS EditDate,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)  
    GROUP BY 
        p.Id, u.DisplayName, ph.UserDisplayName, ph.CreationDate, p.Title, p.Body, p.Tags, 
        p.CreationDate, p.AcceptedAnswerId, pt.Name
),
ProcessedTags AS (
    
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        StringBenchmark
    INNER JOIN (
        SELECT 
            1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
            SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
),
TopTags AS (
    
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PostEngagement AS (
    
    SELECT 
        sb.PostId,
        sb.Title,
        sb.OwnerDisplayName,
        sb.PostType,
        sb.CommentCount,
        COALESCE(VoteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(VoteCounts.DownVotes, 0) AS DownVotes
    FROM 
        StringBenchmark sb
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VoteCounts ON sb.PostId = VoteCounts.PostId
)

SELECT 
    pe.PostId,
    pe.Title,
    pe.OwnerDisplayName,
    pe.PostType,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes,
    tt.Tag AS TopTag
FROM 
    PostEngagement pe
JOIN 
    TopTags tt ON pe.PostId IN (SELECT PostId FROM ProcessedTags WHERE Tag = tt.Tag)
ORDER BY 
    pe.UpVotes DESC, pe.CommentCount DESC;
