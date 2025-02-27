
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) as tag 
                              FROM (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                                    UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
                              WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tags) AS TagCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.ViewCount > 1000
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        p.CommentCount, p.Body, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score + (ps.UpVotes - ps.DownVotes) * 2 AS EngagementScore
    FROM 
        PostStatistics ps
    WHERE 
        ps.TagCount > 0
)
SELECT 
    tp.Title,
    tp.EngagementScore,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalComments,
    ps.HighestBadgeClass
FROM 
    TopPosts tp
JOIN 
    PostStatistics ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.EngagementScore DESC
LIMIT 10;
