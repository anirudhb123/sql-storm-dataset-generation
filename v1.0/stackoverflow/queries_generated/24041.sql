WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,
           SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, p.OwnerUserId
),
AverageVoteCounts AS (
    SELECT OwnerUserId,
           AVG(UpVotes * 1.0 / NULLIF((UpVotes + DownVotes), 0)) AS AvgUpVoteRatio,
           SUM(UpVotes) AS TotalUpVotes,
           SUM(DownVotes) AS TotalDownVotes
    FROM (
        SELECT OwnerUserId, 
               UpVotes, 
               DownVotes 
        FROM RankedPosts 
        WHERE rn = 1
    ) sub
    GROUP BY OwnerUserId
),
UserDetails AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           a.AvgUpVoteRatio
    FROM Users u
    LEFT JOIN AverageVoteCounts a ON u.Id = a.OwnerUserId
    WHERE u.Reputation > 100 AND (a.AvgUpVoteRatio IS NULL OR a.AvgUpVoteRatio > 0.5)
)
SELECT ud.DisplayName,
       ud.Reputation,
       COALESCE(r.TotalUpVotes, 0) AS UserTotalUpVotes,
       COALESCE(r.TotalDownVotes, 0) AS UserTotalDownVotes
FROM UserDetails ud
LEFT JOIN (
    SELECT OwnerUserId,
           SUM(UpVotes) AS TotalUpVotes,
           SUM(DownVotes) AS TotalDownVotes
    FROM RankedPosts
    GROUP BY OwnerUserId
) r ON ud.UserId = r.OwnerUserId
ORDER BY ud.Reputation DESC, UserTotalUpVotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additional analysis for closed questions
SELECT p.Title AS ClosedQuestionTitle,
       u.DisplayName AS OwnerDisplayName,
       ph.CreationDate AS CloseDate,
       ph.Comment AS CloseReason,
       COUNT(DISTINCT v.UserId) AS VoteCount
FROM Posts p
JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.PostTypeId = 1 -- Only questions
GROUP BY p.Title, u.DisplayName, ph.CreationDate, ph.Comment
HAVING COUNT(DISTINCT v.UserId) > 5
ORDER BY CloseDate DESC;
