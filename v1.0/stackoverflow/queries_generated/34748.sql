WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all answers to questions
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId AS UserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId AS UserId,
        Level + 1
    FROM Posts p
    INNER JOIN Posts a ON p.Id = a.ParentId -- Join answers to their questions
    WHERE a.PostTypeId = 2
),

RecentPostHistory AS (
    -- CTE to get the most recent changes in post history
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn -- Rank changes by date
    FROM PostHistory ph
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Changes in the last 30 days
),

UserVotes AS (
    -- CTE to find the total votes for each post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),

FinalReport AS (
    -- Combine all gathered data into a final report
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(up.UpVotes, 0) AS UpVotes,
        COALESCE(dn.DownVotes, 0) AS DownVotes,
        ph.UserDisplayName AS RecentEditor,
        ph.CreationDate AS RecentEditDate,
        ph.PostHistoryTypeId
    FROM Posts p
    LEFT JOIN UserVotes up ON p.Id = up.PostId
    LEFT JOIN UserVotes dn ON p.Id = dn.PostId
    LEFT JOIN RecentPostHistory ph ON p.Id = ph.PostId AND ph.rn = 1 -- Only the most recent edit
    WHERE p.PostTypeId = 1 -- Filter to include only questions
)

SELECT 
    rh.PostId,
    rh.PostTitle,
    rh.UpVotes,
    rh.DownVotes,
    COUNT(DISTINCT a.PostId) AS AnswerCount,
    MAX(ph.RecentEditor) AS RecentEditor,
    MAX(ph.RecentEditDate) AS RecentEditDate
FROM FinalReport rh
LEFT JOIN RecursivePostHierarchy a ON rh.PostId = a.PostId
GROUP BY rh.PostId, rh.PostTitle, rh.UpVotes, rh.DownVotes
ORDER BY rh.UpVotes DESC, AnswerCount DESC
LIMIT 10; -- Top 10 voted questions with their responses
