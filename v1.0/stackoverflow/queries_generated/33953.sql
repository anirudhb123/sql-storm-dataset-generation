WITH RecursivePostHierarchy AS (
    -- This CTE will recursively fetch all answers related to their questions
    SELECT p.Id AS PostId, p.Title, p.ParentId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rp ON p.ParentId = rp.PostId
    WHERE p.PostTypeId = 2 -- Answers
),
PostVoteSummary AS (
    -- This CTE summarizes votes for posts
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    -- This CTE fetches recently closed posts
    SELECT 
        hp.PostId, 
        hp.CreationDate, 
        hp.UserDisplayName, 
        hp.Comment, 
        ROW_NUMBER() OVER (PARTITION BY hp.PostId ORDER BY hp.CreationDate DESC) AS CloseHistoryRank
    FROM PostHistory hp
    WHERE hp.PostHistoryTypeId = 10 -- Post Closed
),
PopularTags AS (
    -- Summarizing tags associated with posts
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    COALESCE(pv.Upvotes, 0) AS Upvotes,
    COALESCE(pv.Downvotes, 0) AS Downvotes,
    cp.CreationDate AS ClosedDate,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS CloseComment,
    (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
     FROM PostHistory ph
     JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id 
     WHERE ph.PostId = rp.PostId) AS HistoryTypes,
    (SELECT STRING_AGG(DISTINCT tt.TagName, ', ') 
     FROM Tags tt 
     JOIN Posts pp ON pp.Tags LIKE '%' || tt.TagName || '%'
     WHERE pp.Id = rp.PostId) AS AssociatedTags,
    pt.PostId AS PopularPostId,
    pt.TagName AS PopularTag
FROM RecursivePostHierarchy rp
LEFT JOIN PostVoteSummary pv ON pv.PostId = rp.PostId
LEFT JOIN ClosedPosts cp ON cp.PostId = rp.PostId AND cp.CloseHistoryRank = 1
LEFT JOIN PopularTags pt ON pt.PostCount >= 5
ORDER BY rp.Level, rp.PostId;
