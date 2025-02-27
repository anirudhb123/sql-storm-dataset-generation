WITH RecursivePosts AS (
    -- CTE to find all answers and their associated questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreateDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreateDate,
        a.AcceptedAnswerId,
        rp.Level + 1
    FROM Posts a
    JOIN RecursivePosts rp ON a.ParentId = rp.PostId -- Getting answers related to questions
    WHERE a.PostTypeId = 2  -- Answers only
),
UserVoteDetails AS (
    -- Summarizing votes for users
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE ph.PostHistoryTypeId = 10  -- Close operations
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerName,
    ud.UpVotes,
    ud.DownVotes,
    COALESCE(pcr.CloseReasons, 'Not Closed') AS CloseReasons,
    COUNT(DISTINCT c.Id) AS CommentCount,
    p.ViewCount,
    rp.Level AS AnswerLevel
FROM RecursivePosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserVoteDetails ud ON u.Id = ud.UserId
LEFT JOIN Posts p ON rp.PostId = p.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN PostCloseReasons pcr ON p.Id = pcr.PostId
WHERE rp.Level <= 3  -- Limit to only first three levels of answers
GROUP BY 
    rp.PostId, rp.Title, u.DisplayName, ud.UpVotes, 
    ud.DownVotes, pcr.CloseReasons, p.ViewCount, rp.Level
ORDER BY 
    rp.CreateDate DESC;
