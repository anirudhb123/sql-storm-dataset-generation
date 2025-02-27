WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 
           CAST(DisplayName AS VARCHAR(255)) AS Path
    FROM Users
    WHERE Id = 1  -- Assuming starting from a root user
    
    UNION ALL
    
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           CONCAT(uh.Path, ' -> ', u.DisplayName)
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id + 1  -- Assuming child relation based on Id
),
PostData AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate,
           COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVotes,
           SUM(v.VoteTypeId = 3) AS DownVotes,
           COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT pd.*, 
           RANK() OVER (ORDER BY pd.UpVotes DESC, pd.CommentCount DESC) AS VoteRank
    FROM PostData pd
)
SELECT up.DisplayName, 
       rp.Title, 
       rp.CreationDate, 
       rp.CommentCount, 
       rp.UpVotes, 
       rp.DownVotes, 
       rp.BadgeCount, 
       CASE 
           WHEN rp.AcceptedAnswerId > 0 THEN 'Yes' 
           ELSE 'No' 
       END AS HasAcceptedAnswer,
       uh.Path
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserHierarchy uh ON u.Id = uh.Id
WHERE rp.VoteRank <= 10
ORDER BY rp.VoteRank;
