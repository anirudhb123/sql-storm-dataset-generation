
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(COALESCE(p.LastActivityDate, p.CreationDate)) AS MostRecentActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > CAST(DATEADD(YEAR, -1, '2024-10-01 12:34:56') AS DATETIME)
    GROUP BY p.Id, p.OwnerUserId
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ur.DisplayName AS OwnerDisplayName,
        ps.TotalComments,
        ps.UpVotes,
        ps.DownVotes,
        CASE 
            WHEN ps.UpVotes - ps.DownVotes > 0 
            THEN 'Positive' 
            WHEN ps.UpVotes - ps.DownVotes < 0 
            THEN 'Negative' 
            ELSE 'Neutral' 
        END AS VoteSentiment,
        COUNT(ph.Id) AS CloseCount,
        COUNT(ph.Id) AS ReopenCount
    FROM PostStats ps
    LEFT JOIN UserReputation ur ON ps.OwnerUserId = ur.UserId
    LEFT JOIN PostHistory ph ON ps.PostId = ph.PostId
    WHERE ur.ReputationRank <= 10
    AND ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ps.PostId, ur.DisplayName, ps.TotalComments, ps.UpVotes, ps.DownVotes
)
SELECT 
    pd.OwnerDisplayName,
    pd.TotalComments,
    pd.UpVotes,
    pd.DownVotes,
    pd.VoteSentiment,
    (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount,
    (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 11) AS ReopenCount,
    (pd.UpVotes + (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 11) - (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10) - pd.DownVotes) AS EngagementScore
FROM PostDetails pd
WHERE (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10) > (SELECT COUNT(Id) FROM PostHistory ph WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 11)
ORDER BY EngagementScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
