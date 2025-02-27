WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
RecentActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        DENSE_RANK() OVER (ORDER BY rp.CreationDate DESC) AS RecentRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Only the latest post per user
)
SELECT 
    rap.PostId,
    rap.Title,
    rap.OwnerDisplayName,
    rap.Tags,
    rap.CommentCount,
    rap.CreationDate,
    COALESCE(
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = rap.PostId 
         AND v.VoteTypeId = 2), 0) AS UpvoteCount
FROM 
    RecentActivePosts rap
WHERE 
    rap.RecentRank <= 10 -- Limit to top 10 recently active posts
ORDER BY 
    rap.CreationDate DESC;

This SQL query benchmarks string processing by evaluating and aggregating posts from the Stack Overflow schema, focusing specifically on the latest question posts. It utilizes Common Table Expressions (CTEs) for clarity and efficiently organizes the posts by user while counting associated comments and tags. The final selection includes a count of upvotes, showcasing the interconnected nature of posts, votes, and community engagement.
