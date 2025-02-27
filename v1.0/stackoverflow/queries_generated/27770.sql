WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 6) AS CloseVotes,
        (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 7) AS ReopenVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(c.Id) DESC) AS PostsRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only including Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        Upvotes,
        Downvotes,
        CloseVotes,
        ReopenVotes
    FROM 
        RankedPosts
    WHERE 
        PostsRank <= 5
),
PostStatistics AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount,
        AVG(CommentCount) AS AvgComments,
        AVG(Upvotes) AS AvgUpvotes,
        AVG(Downvotes) AS AvgDownvotes,
        SUM(CloseVotes) AS TotalCloseVotes,
        SUM(ReopenVotes) AS TotalReopenVotes
    FROM 
        TopPosts
    GROUP BY 
        Tags
)
SELECT 
    t.TagName,
    ps.PostCount,
    ps.AvgComments,
    ps.AvgUpvotes,
    ps.AvgDownvotes,
    ps.TotalCloseVotes,
    ps.TotalReopenVotes
FROM 
    PostStatistics ps
JOIN 
    Tags t ON ps.Tags LIKE '%' || t.TagName || '%'
ORDER BY 
    ps.PostCount DESC, 
    ps.AvgUpvotes DESC;
