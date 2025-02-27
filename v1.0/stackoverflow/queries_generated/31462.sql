WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        ph.Level + 1,
        p2.CreationDate,
        p2.LastActivityDate
    FROM 
        Posts p2
    INNER JOIN RecursivePostHierarchy ph ON p2.ParentId = ph.PostId
),

PostStats AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Downvotes
        COUNT(DISTINCT v.Id) AS TotalVotes,
        MAX(ph.LastActivityDate) AS LastActivityDate,
        COUNT(DISTINCT ph.PostId) AS Depth
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Comments c ON c.PostId = ph.PostId
    LEFT JOIN 
        Votes v ON v.PostId = ph.PostId
    GROUP BY 
        ph.PostId
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 50  -- Popular tags with more than 50 posts
),

RecentPostUpdates AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.LastActivityDate,
        u.DisplayName AS LastEditor,
        p.Score
    FROM 
        Posts p
    JOIN 
        Users u ON p.LastEditorUserId = u.Id
    JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.PostId
    WHERE 
        p.LastEditDate > CURRENT_TIMESTAMP - INTERVAL '30 days' -- Posts edited in the last 30 days
)

SELECT 
    t.TagName,
    ps.PostId,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.TotalVotes,
    ps.LastActivityDate,
    rpu.Title AS RecentlyUpdatedTitle,
    rpu.LastEditor,
    rpu.Score,
    ph.Depth
FROM 
    PostStats ps
INNER JOIN 
    PopularTags t ON ps.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' + t.TagName + '%')
LEFT JOIN 
    RecentPostUpdates rpu ON ps.PostId = rpu.PostId
LEFT JOIN 
    RecursivePostHierarchy ph ON ps.PostId = ph.PostId
WHERE 
    ps.CommentCount > 5
ORDER BY 
    ps.UpVotes DESC, ps.LastActivityDate DESC;
