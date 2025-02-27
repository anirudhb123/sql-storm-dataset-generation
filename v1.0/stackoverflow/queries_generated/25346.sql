WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags
),
FilteredRankedPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE Rank <= 10
)
SELECT 
    r.PostId,
    r.Title,
    r.Tags,
    r.CommentCount,
    r.UniqueVoterCount,
    r.UpvoteCount,
    r.DownvoteCount,
    b.Name AS UserBadge
FROM 
    FilteredRankedPosts r
LEFT JOIN 
    Users u ON r.PostId = u.Id 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
ORDER BY 
    r.UpvoteCount DESC, r.CommentCount DESC;

This SQL query benchmarks string processing by selecting the top 10 posts based on comment count and upvotes within the last year, while aggregating data from related tables such as `Comments`, `Votes`, and `Badges`. The final result set displays relevant details about each post along with any applicable badges held by the user who created the post.
