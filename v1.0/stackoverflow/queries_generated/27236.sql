WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.CreationDate,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostStatistics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Author,
        tp.CreationDate,
        tp.CommentCount,
        tp.AnswerCount,
        CONCAT('This post has ', tp.CommentCount, ' comments and ', tp.AnswerCount, ' answers.') AS StatsSummary
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.StatsSummary,
    STRING_AGG(t.TagName, ', ') AS TagsList
FROM 
    PostStatistics ps
LEFT JOIN 
    Tags t ON POSITION(t.TagName IN ps.Tags) > 0
GROUP BY 
    ps.PostId, ps.Title, ps.Author, ps.CreationDate, ps.StatsSummary
ORDER BY 
    ps.CreationDate DESC;
