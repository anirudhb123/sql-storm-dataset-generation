WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        pe.CommentCount,
        pe.UpVotes,
        pe.DownVotes,
        COALESCE(rp.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM RecentPosts rp
    JOIN PostEngagement pe ON rp.PostId = pe.PostId
    WHERE rp.RN <= 10  -- Top 10 recent posts of each type
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ClosureReasons
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened posts
    GROUP BY ph.PostId, ph.UserDisplayName, ph.CreationDate
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        COALESCE(cph.ClosureReasons, 'No Closure') AS ClosureReasons
    FROM TopPosts tp
    LEFT JOIN ClosedPostHistory cph ON tp.PostId = cph.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.ClosureReasons,
    CASE 
        WHEN fr.UpVotes > fr.DownVotes THEN 'Positive Engagement'
        WHEN fr.UpVotes < fr.DownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement' 
    END AS EngagementSentiment,
    CASE 
        WHEN fr.ClosureReasons IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM FinalResults fr
ORDER BY fr.CreationDate DESC, fr.UpVotes DESC, fr.CommentCount DESC;

