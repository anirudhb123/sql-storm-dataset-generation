WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only Questions
),
UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM UserVoteSummary u
)
SELECT 
    p.Title AS QuestionTitle,
    p.Score AS QuestionScore,
    p.CreationDate AS QuestionDate,
    u.DisplayName AS UserName,
    us.Reputation AS UserReputation,
    us.UpVotesCount,
    us.DownVotesCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS TotalVotes,
    COALESCE(MAX(ph.Comment), 'No history available') AS LastPostHistoryComment
FROM RecursivePostCTE p
JOIN Users u ON p.OwnerUserId = u.Id
JOIN UserVoteSummary us ON u.Id = us.UserId
LEFT JOIN Comments c ON c.PostId = p.PostId
LEFT JOIN PostHistory ph ON ph.PostId = p.PostId
WHERE 
    p.Score >= 10
    AND us.UpVotesCount > us.DownVotesCount
    AND (us.Reputation >= 100 OR us.UserId IN (SELECT UserId FROM TopUsers WHERE UserRank <= 5))
GROUP BY 
    p.Title, p.Score, p.CreationDate, u.DisplayName, us.Reputation, us.UpVotesCount, us.DownVotesCount
HAVING 
    COUNT(DISTINCT c.Id) > 5
ORDER BY 
    p.CreationDate DESC;
