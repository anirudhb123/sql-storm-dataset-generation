WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY u.Id, u.DisplayName
),
PostHistoryData AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11, 12, 19) -- Close or reopen actions
),
PostInteractionCounts AS (
    SELECT
        p.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.PostId
)
SELECT
    u.DisplayName AS UserDisplayName,
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.ViewCount,
    ra.CommentCount,
    ra.UpVoteCount,
    ra.DownVoteCount,
    COALESCE(h.UserDisplayName, 'N/A') AS LastEditor,
    COALESCE(ph.Comment, '') AS CloseReason,
    utc.QuestionsAsked,
    utc.QuestionsCount,
    utc.AnswersCount,
    pic.TotalUpVotes,
    pic.TotalDownVotes,
    pic.TotalComments
FROM RankedPosts ra
JOIN Users u ON ra.OwnerUserId = u.Id
LEFT JOIN PostHistoryData ph ON ra.PostId = ph.PostId
LEFT JOIN RecentUserActivity utc ON u.Id = utc.UserId
LEFT JOIN PostInteractionCounts pic ON ra.PostId = pic.PostId
WHERE ra.rn = 1
ORDER BY ra.CreationDate DESC;
