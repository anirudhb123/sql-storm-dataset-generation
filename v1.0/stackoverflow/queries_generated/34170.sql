WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),

UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

TopPostsByTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    JOIN Tags t ON tag_name = t.TagName
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'  -- Filter for the last year
    GROUP BY p.Id, p.Title
    ORDER BY COUNT(t.Id) DESC
    LIMIT 10
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Post closed
    ORDER BY ph.CreationDate DESC
)

SELECT 
    p.Title AS PostTitle,
    rph.Level AS PostHierarchyLevel,
    uvs.DisplayName AS UserName,
    uvs.TotalUpvotes,
    uvs.TotalDownvotes,
    t.Tags,
    cp.ClosedBy,
    cp.ClosedDate,
    cp.CloseReason
FROM RecursivePostHierarchy rph
JOIN Posts p ON rph.PostId = p.Id
JOIN UserVoteStatistics uvs ON p.OwnerUserId = uvs.UserId
LEFT JOIN TopPostsByTags t ON p.Id = t.PostId
LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
WHERE p.ViewCount > 1000  -- Filter for popular posts
ORDER BY rph.Level, uvs.TotalUpvotes DESC;
