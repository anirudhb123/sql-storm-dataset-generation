WITH RecursivePostHierarchy AS (
    -- CTE to build a hierarchy of posts
    SELECT 
        Id AS PostId, 
        Title, 
        ParentId, 
        0 AS Level 
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        Level + 1 
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    -- CTE to get user statistics based on votes and post interactions
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopTags AS (
    -- CTE to find the top tags used in posts
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, ','))) AS Tag,
        COUNT(*) AS TagCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY Tag
    ORDER BY TagCount DESC
    LIMIT 10
),
PostHistoryDetails AS (
    -- CTE to summarize post history, including latest edits and closures
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 24 THEN ph.CreationDate END) AS LastEditedDate,
        STRING_AGG(DISTINCT ph.Comment) AS EditComments
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    p.PostId,
    p.Title,
    COALESCE(r.Level, 0) AS PostLevel,
    u.TotalPosts,
    u.TotalComments,
    u.UpVotes,
    u.DownVotes,
    u.TotalScore,
    t.Tag,
    ph.ClosedDate,
    ph.LastEditedDate,
    ph.EditComments
FROM Posts p
LEFT JOIN RecursivePostHierarchy r ON p.Id = r.PostId
LEFT JOIN UserPostStats u ON p.OwnerUserId = u.UserId
LEFT JOIN TopTags t ON p.Tags LIKE '%' || t.Tag || '%'
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
WHERE p.CreationDate > NOW() - INTERVAL '1 year'
ORDER BY u.TotalScore DESC, ph.ClosedDate DESC, u.TotalPosts DESC
LIMIT 100;
