WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
),
PostWithVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title AS ClosedTitle,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseComment
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
)
SELECT 
    pws.PostId,
    pws.Title,
    pws.CreationDate,
    pws.ViewCount,
    pws.UpVotes,
    pws.DownVotes,
    pws.AcceptedVotes,
    RPT.UserDisplayName AS LastEditor,
    RPT.CreationDate AS LastEditDate,
    COALESCE(cp.ClosedPostId, 'Not Closed') AS ClosedPostId,
    COALESCE(cp.ClosedTitle, 'N/A') AS ClosedTitle,
    COALESCE(cp.CloseDate, 'N/A') AS CloseDate,
    COALESCE(cp.ClosedBy, 'N/A') AS ClosedBy,
    COALESCE(cp.CloseComment, 'N/A') AS CloseComment
FROM PostWithVoteSummary pws
LEFT JOIN RecursivePostHistory RPT ON pws.PostId = RPT.PostId AND RPT.rn = 1
LEFT JOIN ClosedPosts cp ON pws.PostId = cp.ClosedPostId
WHERE pws.ViewCount > 1000
ORDER BY pws.UpVotes DESC, pws.ViewCount DESC;
