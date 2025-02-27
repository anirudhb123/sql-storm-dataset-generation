WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Selecting only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM Posts p
    JOIN RecursivePostCTE rp ON p.ParentId = rp.PostId
),
PostStatistics AS (
    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        AVG(ph.Score) AS AverageScore,
        MAX(ph.CreationDate) AS LastHistoryChange
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS Score FROM PostHistory GROUP BY PostId) AS ph ON ph.PostId = p.Id
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation > 0
),
TopPosts AS (
    SELECT 
        ps.*,
        ur.UserRank,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.UpVoteCount DESC) AS UserPostRank
    FROM PostStatistics ps
    JOIN UserReputation ur ON ps.OwnerUserId = ur.Id
    WHERE ps.CommentCount > 0
),
RankedPosts AS (
    SELECT 
        tp.*,
        RANK() OVER (ORDER BY tp.UpVoteCount DESC) AS GlobalRank
    FROM TopPosts tp
)
SELECT 
    rp.GlobalRank,
    rp.Title,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.AverageScore,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    rp.LastHistoryChange,
    rp.UserRank AS OwnerUserRank
FROM RankedPosts rp
JOIN UserReputation ur ON rp.OwnerUserId = ur.Id
WHERE rp.UserPostRank <= 5
ORDER BY rp.GlobalRank, rp.OwnerReputation DESC;
