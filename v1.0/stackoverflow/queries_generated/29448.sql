WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.AnswerCount) AS TotalAnswers,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UNNEST(string_to_array(rp.Tags, '>')) AS tag ON true
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag)
WHERE 
    rp.PostRank = 1 -- Get only the latest post for each user
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 10;

This SQL query benchmarks string processing and provides valuable insights into the activity of users on the platform over the past year. It aggregates data on the total number of posts, views, comments, and answers for each user while also listing the unique tags assigned to their most recent posts. The use of CTE and string processing functions demonstrates the capabilities and efficiency of SQL in handling complex data structures.
