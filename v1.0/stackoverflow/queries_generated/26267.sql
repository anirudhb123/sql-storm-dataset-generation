WITH ProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p               
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        pp.*,
        (pp.UpVoteCount - pp.DownVoteCount) AS NetVotes,
        (pp.Score + pp.TagCount * 2 + pp.CommentCount) AS EngagementScore
    FROM 
        ProcessedPosts pp
    WHERE 
        pp.ViewCount > 1000
),
TopPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY EngagementScore DESC) AS Rank
    FROM 
        PopularPosts
)
SELECT 
    t.Title,
    t.ViewCount,
    t.CommentCount,
    t.EngagementScore,
    u.DisplayName AS OwnerDisplayName
FROM 
    TopPosts t
JOIN 
    Users u ON t.OwnerUserId = u.Id
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;

This query retrieves the top 10 posts created in the last year from a set of posts that have been viewed more than 1000 times. It calculates each post's engagement score based on an algorithm that factors in the score, comment count, and the number of tags (weighted). The results include the title of the post, its view count, comment count, engagement score, and the display name of the user who owns the post.
