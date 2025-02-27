
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS ChangeTypes,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Score,
        p.ViewCount,
        @rank := IF(@prev_post_type = p.PostTypeId, @rank + 1, 1) AS rnk,
        @prev_post_type := p.PostTypeId
    FROM Posts p, (SELECT @rank := 0, @prev_post_type := NULL) rnk_init
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.PostTypeId, p.Score DESC, p.ViewCount DESC
)

SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.TotalPosts,
    uvs.TotalQuestions,
    uvs.TotalAnswers,
    ph.ChangeTypes,
    ph.HistoryCount,
    ph.LastChangeDate,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount
FROM UserVoteStats uvs
LEFT JOIN PostHistoryDetails ph ON uvs.UserId = ph.PostId
JOIN TopPosts tp ON tp.PostId = ph.PostId 
WHERE tp.rnk <= 5
ORDER BY uvs.UpVotes DESC, uvs.DownVotes ASC, uvs.TotalPosts DESC;
