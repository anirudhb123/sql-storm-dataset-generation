WITH RecursiveVoteCounts AS (
    SELECT PostId,
           COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
           p.CreationDate,
           ph.Comment AS CloseReason,
           ph.CreationDate AS CloseDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
    WHERE p.PostTypeId = 1 -- Only consider Questions
),
CombinedPostStats AS (
    SELECT pd.PostId,
           pd.Title,
           pd.OwnerDisplayName,
           pd.CreationDate,
           RVC.UpVotes,
           RVC.DownVotes,
           pd.CloseReason,
           pd.UserPostRank,
           CASE
               WHEN RVC.TotalVotes = 0 THEN NULL
               ELSE (RVC.UpVotes::FLOAT / RVC.TotalVotes) * 100
           END AS UpvotePercentage
    FROM PostDetails pd
    JOIN RecursiveVoteCounts RVC ON pd.PostId = RVC.PostId
)
SELECT DISTINCT cps.PostId,
                cps.Title,
                cps.OwnerDisplayName,
                cps.CreationDate,
                cps.UpVotes,
                cps.DownVotes,
                cps.CloseReason,
                cps.UpvotePercentage,
                CASE 
                    WHEN cps.UserPostRank = 1 THEN 'Most Recent Question'
                    WHEN cps.UpvotePercentage IS NULL THEN 'No Votes Cast'
                    WHEN cps.UpvotePercentage > 75 THEN 'High Popularity'
                    ELSE 'Regular Question'
                END AS PostStatus
FROM CombinedPostStats cps
WHERE (cps.UpVotes > 5 OR cps.DownVotes > 2)
  AND cps.CloseReason IS NULL
  AND NOT EXISTS (
      SELECT 1
      FROM Badges b
      WHERE b.UserId = cps.OwnerUserId
      AND b.Class = 1 -- Gold badges
  )
ORDER BY cps.UpvotePercentage DESC NULLS LAST, 
         cps.CreationDate DESC;
