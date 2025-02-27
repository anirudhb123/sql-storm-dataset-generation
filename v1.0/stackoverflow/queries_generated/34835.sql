-- Performance Benchmarking Query

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.PostTypeId,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0  -- Only include posts with comments
          AND rp.rn <= 5  -- Get only latest 5 posts per user
),
PostWithBadges AS (
    SELECT 
        fp.*,
        b.Name AS BadgeName
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON fp.OwnerUserId = b.UserId
    WHERE 
        b.Date >= fp.CreationDate  -- Badge given on or after post creation
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    COALESCE(b.BadgeName, 'No Badge') AS BadgeName
FROM 
    PostWithBadges p
JOIN 
    Users u ON p.OwnerUserId = u.Id
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC
LIMIT 100;  -- Limit result to top 100 posts

This query benchmarks by following these steps:

1. **CTE (Common Table Expressions)**: The first CTE (`RankedPosts`) calculates the number of comments, upvotes, and downvotes for each post and ranks them by user creation date.
   
2. **Filtering**: The second CTE (`FilteredPosts`) filters posts with comments and limits to the latest five posts per user.
   
3. **Badge Information**: The third CTE (`PostWithBadges`) joins post data with user badges, ensuring that only badges awarded on or after post creation are included.

4. **Final Presentation**: The main query selects relevant fields from the combined data, joining with the `Users` table to fetch the display name of the post authors. It orders the results by score and post creation date, limiting the output to the top 100 posts for efficient performance benchmarking. 

This SQL query utilizes several advanced constructs, including CTEs, outer joins, aggregates, and conditional aggregations, all of which can be beneficial for understanding performance implications in complex queries.
