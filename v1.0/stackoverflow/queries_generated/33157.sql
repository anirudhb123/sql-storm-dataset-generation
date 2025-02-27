WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        1 AS Level,
        CAST(Title AS VARCHAR(MAX)) AS Path
    FROM Posts
    WHERE ParentId IS NULL  -- Start from the top-level posts (questions)
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        r.Level + 1,
        CAST(r.Path + ' > ' + p.Title AS VARCHAR(MAX))
    FROM Posts p
    JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,  -- Count Upvotes
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes  -- Count Downvotes
    FROM Votes
    GROUP BY PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 24 THEN ph.CreationDate END) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),
AggregatePostData AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(ph.ClosedDate, NULL) AS ClosedDate,
        COALESCE(ph.ReopenedDate, NULL) AS ReopenedDate,
        COALESCE(ph.LastEditDate, NULL) AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN PostHistoryInfo ph ON p.Id = ph.PostId
),
RankedPosts AS (
    SELECT *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS OverallRank
    FROM AggregatePostData
)
SELECT 
    r.PostId,
    r.Title,
    r.UpVotes,
    r.DownVotes,
    r.ClosedDate,
    r.ReopenedDate,
    r.LastEditDate,
    r.UserPostRank,
    r.OverallRank,
    COALESCE(Tags.TagCount, 0) AS TagCount,
    ARRAY_TO_STRING(string_to_array(Tags.Title, ' '), ';') AS TagsUsed
FROM RankedPosts r
LEFT JOIN (
    SELECT 
        p.Id, 
        COUNT(t.Id) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Title
    FROM Posts p
    LEFT JOIN unnest(string_to_array(p.Tags, '<>')) AS tag ON tag IS NOT NULL
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id
) AS Tags ON Tags.Id = r.PostId
WHERE r.OverallRank <= 100  -- Limit the output to top 100 posts based on score and views
ORDER BY r.OverallRank;

