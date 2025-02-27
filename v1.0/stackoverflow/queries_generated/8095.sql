WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeleteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseCount,
        ps.DeleteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        u.CreationDate AS UserCreationDate
    FROM PostStatistics ps
    JOIN Users u ON ps.OwnerUserId = u.Id
    WHERE ps.UpVoteCount > 10 AND ps.CommentCount > 5
    ORDER BY ps.UpVoteCount DESC
    LIMIT 10
)
SELECT 
    pp.Title,
    pp.CommentCount,
    pp.UpVoteCount,
    pp.DownVoteCount,
    pp.CloseCount,
    pp.DeleteCount,
    pp.OwnerDisplayName,
    pp.Reputation,
    pp.UserCreationDate
FROM PopularPosts pp
JOIN UserVoteCounts uvc ON pp.OwnerUserId = uvc.UserId
WHERE uvc.TotalVotes > 20;
