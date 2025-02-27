WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Consider only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank,
        COUNT(*) OVER () AS TotalPosts
    FROM 
        RankedPosts rp
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.Tags,
    ps.CommentCount,
    ps.Rank,
    ps.TotalPosts,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = ps.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = ps.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 10 -- Top 10 posts
ORDER BY 
    ps.Rank;

This SQL query performs the following operations:

1. Creates a Common Table Expression (CTE) named `RankedPosts` that aggregates posts of type "Question," counting their tags and comments, and also displays their respective view count and score.
  
2. A second CTE, `PostStatistics`, ranks the posts based on score and view count while counting the total number of posts.

3. Finally, the main SELECT query fetches the top 10 ranked posts, along with their related statistics (tags, comment count), and adds the count of upvotes and downvotes for each post.
