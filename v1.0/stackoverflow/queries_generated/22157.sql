WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(up.UsersUpvoted, 0) AS UsersUpvoted
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            MAX(AcceptedAnswerId) AS AcceptedAnswerId
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 -- Questions
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(UserId) AS UsersUpvoted
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2 -- Upvotes
        GROUP BY 
            PostId
    ) up ON p.Id = up.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL 
    UNION ALL
    SELECT 
        ph.PostId,
        ph.Title,
        ph.CreationDate,
        ph.Score,
        ph.ViewCount,
        ph.Body,
        ph.Tags,
        COALESCE(ph.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(up.UsersUpvoted, 0) AS UsersUpvoted
    FROM 
        Posts ph
    JOIN 
        RecursivePosts rp ON rp.AcceptedAnswerId = ph.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(UserId) AS UsersUpvoted
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2 -- Upvotes
        GROUP BY 
            PostId
    ) up ON ph.Id = up.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    COALESCE(rp.Body, 'No content available') AS BodyContent,
    CASE 
        WHEN rp.UserUpvoted IS NULL THEN 'No Upvotes'
        WHEN rp.UserUpvoted > 0 THEN 'Upvoted'
        ELSE 'Not Upvoted'
    END AS UpvoteStatus,
    COUNT(c.Id) AS CommentCount,
    DENSE_RANK() OVER (PARTITION BY rp.Tags ORDER BY rp.Score DESC) AS RankByScore
FROM 
    RecursivePosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.Tags, rp.Body
HAVING 
    COUNT(c.Id) > 5 -- Only include posts with more than 5 comments
ORDER BY 
    RankByScore, rp.CreationDate DESC;

-- This query utilizes Common Table Expressions (CTEs), recursive joins, window functions, 
-- COALESCE for NULL handling, and advanced filtering, providing a complex benchmark scenario 
-- to analyze performance on potentially large datasets in the StackOverflow schema.
