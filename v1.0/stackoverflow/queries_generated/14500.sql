-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        AVG(v.VoteTypeId = 2) AS AverageUpVotes,
        AVG(v.VoteTypeId = 3) AS AverageDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.TotalComments,
    ps.AverageUpVotes,
    ps.AverageDownVotes,
    ts.TagName,
    ts.PostCount
FROM 
    PostStatistics ps
LEFT JOIN 
    TagStatistics ts ON ps.PostId = ts.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
