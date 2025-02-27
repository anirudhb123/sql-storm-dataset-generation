WITH UsersRanked AS (
    SELECT 
        Id, 
        Reputation, 
        DisplayName, 
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        CASE 
            WHEN Reputation > 10000 THEN 'High'
            WHEN Reputation > 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationGroup
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Assuming 2 is for UpMod
        SUM(v.VoteTypeId = 3) AS DownVoteCount  -- Assuming 3 is for DownMod
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts created in the last year
    GROUP BY p.Id, p.PostTypeId, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        postId, 
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10  -- Referencing close actions
    GROUP BY postId
),
Combined AS (
    SELECT 
        ps.PostId, 
        ps.PostTypeId, 
        ps.CreationDate, 
        ps.CommentCount, 
        ps.UpVoteCount, 
        ps.DownVoteCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        ur.DisplayName,
        ur.ReputationGroup
    FROM PostStats ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.postId
    LEFT JOIN UsersRanked ur ON ps.PostId = ur.Id  -- assuming posts have a direct link to users
)
SELECT 
    C.PostId,
    C.PostTypeId,
    C.CreationDate,
    C.CommentCount,
    C.UpVoteCount,
    C.DownVoteCount,
    C.CloseCount,
    C.DisplayName,
    C.ReputationGroup
FROM Combined C
WHERE 
    (C.CloseCount > 0 AND C.UpVoteCount > C.DownVoteCount)  -- Closed but still popular
    OR 
    (C.CloseCount = 0 AND C.CommentCount > 5)               -- Not closed but active
ORDER BY C.CommentCount DESC, C.UpVoteCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;  -- Paginate results, adjust as needed
