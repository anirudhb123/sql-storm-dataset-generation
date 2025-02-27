
WITH UserReputation AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        CreationDate, 
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        CASE 
            WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive'
            ELSE 'Negative or Neutral'
        END AS PostSentiment
    FROM PostStats ps
    JOIN Users u ON ps.OwnerUserId = u.Id
)
SELECT 
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ur.ReputationCategory, 
    pd.PostId, 
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.PostSentiment,
    COALESCE(p.Title, 'No Title') AS PostTitle,
    COALESCE(GROUP_CONCAT(DISTINCT t.TagName), '') AS Tags
FROM UserReputation ur
LEFT JOIN PostDetails pd ON ur.Id = pd.OwnerUserId
LEFT JOIN Posts p ON pd.PostId = p.Id
LEFT JOIN (
    SELECT 
        p.Id AS PostId,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
) t ON t.PostId = p.Id
GROUP BY 
    ur.DisplayName, 
    ur.Reputation, 
    ur.ReputationCategory, 
    pd.PostId, 
    pd.CommentCount, 
    pd.UpVoteCount, 
    pd.DownVoteCount, 
    pd.PostSentiment,
    p.Title 
ORDER BY ur.Reputation DESC, pd.UpVoteCount DESC;
