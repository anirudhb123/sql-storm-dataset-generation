WITH UserReputation AS (
    SELECT 
        Id,
        Reputation, 
        CASE 
            WHEN Reputation > 5000 THEN 'High'
            WHEN Reputation BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.Score, 0) AS Score,
        u.DisplayName AS Author,
        pt.Name AS PostType
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
),
VoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.Author,
        pd.PostType,
        COALESCE(vc.UpVotesCount, 0) AS UpVotes,
        COALESCE(vc.DownVotesCount, 0) AS DownVotes,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        ur.ReputationCategory
    FROM PostDetails pd
    LEFT JOIN VoteCounts vc ON pd.PostId = vc.PostId
    LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
    JOIN UserReputation ur ON pd.Author = ur.DisplayName
)
SELECT 
    *,
    (CASE 
        WHEN CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END) AS PostStatus,
    (UpVotes - DownVotes) AS EngagementScore
FROM FinalResults
ORDER BY EngagementScore DESC, CreationDate DESC
LIMIT 100;
