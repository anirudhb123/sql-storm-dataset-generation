WITH RecursivePostStats AS (
    -- Recursive CTE to gather data regarding nested answers and their scores
    SELECT
        P.Id AS PostId,
        P.Title AS PostTitle,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- only Questions
    UNION ALL
    SELECT
        P.Id AS PostId,
        P.Title AS PostTitle,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        Level + 1
    FROM Posts P
    INNER JOIN RecursivePostStats R ON P.ParentId = R.PostId
),
PostVoteSummary AS (
    -- CTE to calculate UpVotes and DownVotes for each post
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes
    GROUP BY PostId
),
PostHistorySummary AS (
    -- CTE to summarize post history types and associated user changes
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (24, 10, 11) THEN 1 END) AS EditCount,
        MAX(PH.CreationDate) AS LastHistoryUpdateDate
    FROM PostHistory PH
    GROUP BY PH.PostId
),
FinalStats AS (
    -- Join CTEs and calculate final statistics
    SELECT 
        R.PostId,
        R.PostTitle,
        R.OwnerUserId,
        R.Score,
        R.CreationDate,
        COALESCE(PVS.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(PVS.TotalDownVotes, 0) AS TotalDownVotes,
        COALESCE(PHS.LastClosedDate, 'No Closures') AS LastClosedStatus,
        PHS.EditCount,
        PHS.LastHistoryUpdateDate
    FROM RecursivePostStats R
    LEFT JOIN PostVoteSummary PVS ON R.PostId = PVS.PostId
    LEFT JOIN PostHistorySummary PHS ON R.PostId = PHS.PostId
)
-- Final selection with ranking and filtering
SELECT 
    FS.PostId,
    FS.PostTitle,
    FS.OwnerUserId,
    FS.Score,
    FS.TotalUpVotes,
    FS.TotalDownVotes,
    FS.LastClosedStatus,
    FS.EditCount,
    FS.LastHistoryUpdateDate,
    RANK() OVER (ORDER BY FS.Score DESC) AS RankByScore,
    NTILE(4) OVER (ORDER BY FS.CreationDate DESC) AS CreationQuartile
FROM FinalStats FS
WHERE FS.EditCount > 0 -- Only consider posts that have been edited
AND FS.TotalUpVotes > FS.TotalDownVotes -- Filter by upvotes more than downvotes
ORDER BY FS.Score DESC;
