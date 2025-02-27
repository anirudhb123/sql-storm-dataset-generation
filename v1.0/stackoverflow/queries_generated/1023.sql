WITH RecentPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY
        p.Id
),
VoteStats AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS LastActionDate,
        STRING_AGG(ph.Comment, ', ') AS Comments
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11) -- for close and reopen actions
    GROUP BY
        ph.PostId, ph.UserId
),
FinalResults AS (
    SELECT
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        rp.CommentCount,
        COALESCE(phd.LastActionDate, 'No Actions') AS LastActionDate,
        CASE
            WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Unanswered'
        END AS AnswerStatus
    FROM
        RecentPosts rp
        LEFT JOIN VoteStats vs ON rp.Id = vs.PostId
        LEFT JOIN PostHistoryDetails phd ON rp.Id = phd.PostId
)
SELECT
    FR.*,
    ROUND((FR.UpVotes::FLOAT / NULLIF(FR.CommentCount, 0)) * 100, 2) AS EngagementRate,
    CASE
        WHEN FR.LastActionDate = 'No Actions' THEN 'N/A'
        ELSE TO_CHAR(FR.LastActionDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS FormattedLastActionDate
FROM
    FinalResults FR
WHERE
    FR.CommentCount > 0
ORDER BY
    FR.CreationDate DESC;
