WITH RankedPosts AS (
  SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(a.Id) AS AnswerCount,
    p.ViewCount,
    STRING_AGG(t.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
  FROM 
    Posts p
  LEFT JOIN 
    Comments c ON c.PostId = p.Id
  LEFT JOIN 
    Posts a ON a.AcceptedAnswerId = p.Id
  LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
  LEFT JOIN 
    PostsTags pt ON pt.PostId = p.Id
  LEFT JOIN 
    Tags t ON t.Id = pt.TagId
  WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
  GROUP BY 
    p.Id, u.DisplayName
),
FilteredPosts AS (
  SELECT 
    rp.* 
  FROM 
    RankedPosts rp 
  WHERE 
    rp.RN <= 5 
    AND rp.CommentCount > 0
)
SELECT 
  fp.PostId,
  fp.Title,
  LEFT(fp.Body, 150) AS ShortBody,  -- Process the body to return only the first 150 characters
  fp.OwnerDisplayName,
  fp.CommentCount,
  fp.AnswerCount,
  fp.ViewCount,
  fp.Tags
FROM 
  FilteredPosts fp
ORDER BY 
  fp.CreationDate DESC;

This SQL query benchmarks string processing by:

1. Ranking posts by their creation date within their type.
2. Filtering down to recent posts created in the last year with at least one comment.
3. Using `STRING_AGG` to gather tags associated with each post.
4. Returning a short version of the post body with only the first 150 characters for processing.
5. Finally, ordering the results by creation date, which helps to analyze recent activity.
