WITH PostAnalytics AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Filter for posts from the last year
    GROUP BY 
        p.Id
), PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        TagName
), TrendingPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.ViewCount,
        pa.CommentCount,
        pa.UpVotes,
        pa.DownVotes,
        pt.TagName
    FROM 
        PostAnalytics pa
    JOIN 
        PopularTags pt ON pt.TagName = ANY(string_to_array(pa.Tags, ','))  -- Correlate popular tags
    WHERE 
        pa.ViewCount > 1000  -- Only consider posts with more than 1000 views
    ORDER BY 
        pa.ViewCount DESC
    LIMIT 10  -- Limit to top 10 results
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    pt.TagName
FROM 
    TrendingPosts tp
JOIN 
    PostTypes t ON tp.PostId = t.Id
WHERE 
    t.Name LIKE '%question%'  -- Filter for questions
ORDER BY 
    tp.ViewCount DESC, tp.UpVotes DESC;  -- Order by views and upvotes
