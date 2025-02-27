
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        LOWER(t.TagName) AS ProcessedTagName
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON true
), TagMetrics AS (
    SELECT 
        PostId,
        ProcessedTagName,
        COUNT(PostId) AS TagFrequency
    FROM 
        ProcessedTags
    GROUP BY 
        PostId, ProcessedTagName
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT c.Id) AS CommentsMade
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        @row_num := @row_num + 1 AS Rank,
        p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_num := 0) r
    WHERE 
        p.PostTypeId = 1  
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tm.ProcessedTagName,
    tm.TagFrequency,
    ue.DisplayName AS UserAuthor,
    ue.UpVotesReceived,
    ue.DownVotesReceived,
    ue.CommentsMade
FROM 
    TopPosts tp
JOIN 
    TagMetrics tm ON tp.PostId = tm.PostId
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    tp.Rank <= 10  
ORDER BY 
    tp.Score DESC, 
    tm.TagFrequency DESC;
