WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.ViewCount, 
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Filter to questions only
),
ClosedPosts AS (
    SELECT DISTINCT ph.PostId, 
                    ph.CreationDate, 
                    ph.UserDisplayName, 
                    MAX(ph.Comment) AS CloseReason 
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY ph.PostId, ph.CreationDate, ph.UserDisplayName
),
PostMetrics AS (
    SELECT p.Id AS PostId,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) as UpVotes, -- Upvotes
           SUM(v.VoteTypeId = 3) as DownVotes, -- Downvotes
           COALESCE(SUM(v.BountyAmount), 0) as TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
)
SELECT rp.Id AS PostId, 
       rp.Title, 
       rp.CreationDate, 
       rp.ViewCount, 
       pm.CommentCount,
       pm.UpVotes, 
       pm.DownVotes, 
       COALESCE(cp.CloseReason, 'Not Closed') AS LatestCloseReason,
       CASE 
           WHEN pm.UpVotes > pm.DownVotes THEN 'Positive Feedback'
           WHEN pm.UpVotes < pm.DownVotes THEN 'Negative Feedback'
           ELSE 'Neutral Feedback'
       END AS FeedbackType,
       CASE 
           WHEN pm.TotalBounty > 0 THEN 'Bountied Post'
           ELSE 'Standard Post' 
       END AS PostCategory,
       CONCAT('Post created on ', TO_CHAR(rp.CreationDate, 'Day'), 
              ' with ', pm.CommentCount, 
              ' comments and a score of ', rp.Score) AS SummaryText

FROM RankedPosts rp
LEFT JOIN ClosedPosts cp ON rp.Id = cp.PostId
LEFT JOIN PostMetrics pm ON rp.Id = pm.PostId
WHERE rp.rn = 1 -- Only considering the latest question for each user
ORDER BY rp.CreationDate DESC;
