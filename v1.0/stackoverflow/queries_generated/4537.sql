WITH UserVotes AS (
    SELECT 
        v.UserId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId, v.VoteTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM Posts p
    LEFT JOIN PostComments pc ON p.Id = pc.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    us.TotalBadges,
    us.TotalAnswers,
    us.TotalScore,
    us.PostCount,
    pd.TotalComments,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostCreationDate,
    uv.UpVotes,
    uv.DownVotes
FROM UserStats us
JOIN Users u ON us.UserId = u.Id
LEFT JOIN PostDetail pd ON pd.PostId = (SELECT TOP 1 p.Id FROM Posts p WHERE p.OwnerUserId = u.Id ORDER BY p.CreationDate DESC)
LEFT JOIN UserVotes uv ON uv.UserId = u.Id
WHERE uv.UpVotes > uv.DownVotes
ORDER BY us.TotalScore DESC, us.TotalAnswers DESC;
