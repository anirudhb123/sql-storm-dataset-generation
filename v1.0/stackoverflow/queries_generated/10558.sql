-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        p.ViewCount,
        p.CreationDate,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.ViewCount,
    ps.CreationDate,
    ps.PostType,
    ARRAY_AGG(DISTINCT ps.TagName) AS Tags,
    COUNT(DISTINCT ps.PostId) OVER () AS TotalPostsCount
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;
