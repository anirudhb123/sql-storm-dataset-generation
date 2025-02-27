WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get all answers and their corresponding parent questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    JOIN 
        Posts a ON p.Id = a.ParentId  -- Linking answers to their parent questions
    WHERE 
        a.PostTypeId = 2  -- Answers
),
PostStatistics AS (
    -- Calculating statistics for posts including vote counts and comment counts
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN bh.UserId IS NOT NULL THEN bh.Id END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges bh ON p.OwnerUserId = bh.UserId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
FilteredPosts AS (
    -- Filtering posts based on their statistics
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ph.Level
    FROM 
        PostStatistics ps
    LEFT JOIN 
        RecursivePostHierarchy ph ON ps.PostId = ph.PostId
    WHERE 
        ps.UpVotes - ps.DownVotes > 10  -- Only include posts with a significant positive score
)
SELECT 
    fp.Title,
    u.DisplayName AS OwnerName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.Level
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
ORDER BY 
    fp.UpVotes DESC, fp.CommentCount DESC;  -- Sorting by votes and comments to give priority to more active posts
