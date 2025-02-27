WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.CreationDate IS NOT NULL) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS RankByAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, u.DisplayName
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(a.AnswerCount) AS AverageAnswers,
        MAX(a.CommentCount) AS MaxComments
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        (SELECT ParentId, COUNT(Id) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    GROUP BY 
        t.TagName
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.AnswerCount,
    r.CommentCount,
    r.TotalVotes,
    t.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageAnswers,
    ts.MaxComments
FROM 
    RankedPosts r
JOIN 
    TagStatistics ts ON ts.PostCount > 0
JOIN 
    LATERAL unnest(string_to_array(r.Tags, ',')) AS t(TagName) ON t.TagName = ts.TagName
WHERE 
    r.RankByAnswers = 1 -- Top answers by user
ORDER BY 
    r.TotalVotes DESC, 
    ts.PostCount DESC
LIMIT 10;
