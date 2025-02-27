
WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsVotedOn
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        post.Id AS PostId,
        post.OwnerUserId,
        COALESCE(pht.Name, 'Other') AS PostHistoryType,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT ph.Id) AS MostEditedRank
    FROM Posts post
    LEFT JOIN PostHistory ph ON post.Id = ph.PostId
    LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    LEFT JOIN Comments c ON post.Id = c.PostId
    LEFT JOIN Votes v ON post.Id = v.PostId
    GROUP BY post.Id, post.OwnerUserId, pht.Name
),
RankedUserVotes AS (
    SELECT 
        uvs.UserId, 
        uvs.DisplayName, 
        @row_number := @row_number + 1 AS VoteRank
    FROM UserVoteStatistics uvs, (SELECT @row_number := 0) AS r
    ORDER BY uvs.UpVotes - uvs.DownVotes DESC
)
SELECT 
    ps.PostId,
    ps.PostHistoryType,
    ps.HistoryCount,
    ps.CommentCount,
    CASE 
        WHEN ps.TotalUpVotes > ps.TotalDownVotes THEN 'Positive'
        WHEN ps.TotalUpVotes < ps.TotalDownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    ru.DisplayName AS MostActiveVoter,
    ru.VoteRank
FROM PostStatistics ps
LEFT JOIN RankedUserVotes ru ON ps.OwnerUserId = ru.UserId
WHERE ps.MostEditedRank = 1 
AND (ps.HistoryCount > 5 OR ps.CommentCount > 10)
ORDER BY ps.HistoryCount DESC, ps.CommentCount DESC
LIMIT 10 OFFSET 10;
