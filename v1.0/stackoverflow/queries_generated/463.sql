WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(ph.UserId, -1) AS UserId
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id, ph.UserId
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.UpVotes,
        pd.DownVotes,
        ud.ReputationCategory,
        ROW_NUMBER() OVER (PARTITION BY ud.ReputationCategory ORDER BY pd.UpVotes DESC) AS PostRank
    FROM PostDetails pd
    JOIN UserReputation ud ON pd.UserId = ud.Id
)
SELECT 
    rp.ReputationCategory,
    COUNT(*) AS PostCount,
    AVG(rp.UpVotes) AS AvgUpVotes,
    AVG(rp.DownVotes) AS AvgDownVotes
FROM RankedPosts rp
WHERE rp.PostRank <= 5
GROUP BY rp.ReputationCategory
ORDER BY rp.ReputationCategory;

SELECT DISTINCT 
    t.TagName,
    COUNT(p.Id) AS PostCount
FROM Tags t
LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY t.TagName
HAVING COUNT(p.Id) > 5;

SELECT 
    p.Title,
    COALESCE(c.UserDisplayName, 'Anonymous') AS Commenter,
    c.Text AS CommentText
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.AcceptedAnswerId IS NULL 
  AND p.CreationDate < NOW() - INTERVAL '30 days'
  AND (c.UserId IS NULL OR c.UserId NOT IN (SELECT Id FROM Users WHERE Reputation < 100))
ORDER BY p.CreationDate DESC;
