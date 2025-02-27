
WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Votes v
    GROUP BY v.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount 
               FROM Comments GROUP BY PostId) pc ON p.Id = pc.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS EditCount 
               FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId,
    (SELECT @row_number := 0, @prev_owner := NULL) r
    ORDER BY p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    pd.PostId,
    pd.Title, 
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    uvc.UpVotes,
    uvc.DownVotes,
    pd.CommentCount,
    pd.EditCount,
    CASE 
        WHEN pd.Score > 100 THEN 'High'
        WHEN pd.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory
FROM PostDetails pd
JOIN UserVoteCounts uvc ON pd.PostId IN (
    SELECT PostId
    FROM Votes
    WHERE UserId = uvc.UserId
    GROUP BY PostId
)
WHERE pd.PostRank <= 10
ORDER BY pd.CreationDate DESC
LIMIT 50;
