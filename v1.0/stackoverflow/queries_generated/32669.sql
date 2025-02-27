WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        Posts rp ON p.ParentId = rp.Id
    WHERE 
        p.PostTypeId = 2 -- Selecting Answers
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 5 THEN 1 END) AS Favorites
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        rp.Level,
        u.Reputation,
        COALESCE(uv.UpVotes, 0) AS UpVotes,
        COALESCE(uv.DownVotes, 0) AS DownVotes,
        COALESCE(uv.Favorites, 0) AS Favorites,
        p.ViewCount,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        Posts p
    LEFT JOIN 
        RecursivePosts rp ON p.Id = rp.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserVotes uv ON uv.UserId = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TopPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY ps.PostStatus ORDER BY ps.ViewCount DESC) AS Rank
    FROM 
        PostStats ps
)

SELECT 
    t.Title,
    t.Reputation,
    t.UpVotes,
    t.DownVotes,
    t.Favorites,
    t.ViewCount,
    t.PostStatus
FROM 
    TopPosts t
WHERE 
    t.Rank <= 10 -- Get top 10 posts by view count for each status
ORDER BY 
    t.PostStatus, t.ViewCount DESC;

-- This query uses recursive CTE to gather post hierarchy along with user vote stats, 
-- creates a summarized view of post stats, and then lists the top posts based on view count grouped by their status.
