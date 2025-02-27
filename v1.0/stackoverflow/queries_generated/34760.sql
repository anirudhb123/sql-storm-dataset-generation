WITH RecursivePosts AS (
    -- CTE to recursively find the hierarchy of posts and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting with top-level questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        rp.Depth + 1
    FROM 
        Posts p
    JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId  -- Joining to find answers
),
UserVotes AS (
    -- CTE to get user votes and calculate their total voting score
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostNotifications AS (
    -- CTE to get posts with notifications about editing history
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS Notifications,
        MAX(ph.CreationDate) AS LastNotificationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 8)  -- Edit-related history types
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id,
    p.Title,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalClosures,
    COALESCE(CONCAT('UpVotes: ', uv.UpVotes, ', DownVotes: ', uv.DownVotes), 'No Votes') AS UserVoteSummary,
    pn.Notifications,
    ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    UserVotes uv ON uv.UserId = p.OwnerUserId
LEFT JOIN 
    PostNotifications pn ON pn.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter to recent posts
    AND p.Title IS NOT NULL
GROUP BY 
    p.Id, uv.UpVotes, uv.DownVotes, pn.Notifications
ORDER BY 
    TotalComments DESC,
    p.LastActivityDate DESC;
