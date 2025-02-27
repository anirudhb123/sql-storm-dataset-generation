WITH RECURSIVE UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        VoteRank
    FROM UserVoteSummary
    WHERE VoteRank <= 10
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.VoteCount, 0) AS TotalVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, v.VoteCount
),
EnhancedPosts AS (
    SELECT 
        pa.*,
        CASE 
            WHEN pa.LastEditDate IS NOT NULL THEN 'Edited'
            ELSE 'Not Edited'
        END AS EditStatus,
        CASE 
            WHEN pa.TotalVotes <= 5 THEN 'Low Activity'
            WHEN pa.TotalVotes BETWEEN 6 AND 20 THEN 'Medium Activity'
            ELSE 'High Activity'
        END AS ActivityLevel
    FROM PostAnalytics pa
),
FinalResult AS (
    SELECT 
        ep.PostId,
        ep.Title,
        ep.CreationDate,
        ep.TotalVotes,
        ep.CommentCount,
        ep.EditStatus,
        ep.ActivityLevel,
        (SELECT GROUP_CONCAT(u.DisplayName) 
         FROM TopUsers u 
         JOIN Votes v ON u.UserId = v.UserId 
         WHERE v.PostId = ep.PostId) AS TopVoters
    FROM EnhancedPosts ep 
    WHERE ep.TotalVotes > 0
)
SELECT 
    fr.*,
    COUNT(DISTINCT ph.PostId) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
    COUNT(DISTINCT ph.PostId) FILTER (WHERE ph.PostHistoryTypeId = 12) AS DeleteCount
FROM FinalResult fr
LEFT JOIN PostHistory ph ON fr.PostId = ph.PostId
GROUP BY fr.PostId;
