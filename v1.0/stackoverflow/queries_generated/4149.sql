WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
AcceptedAnswers AS (
    SELECT 
        p.Id AS AnswerId,
        p.AcceptedAnswerId,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END AS IsAccepted
    FROM Posts p
    WHERE p.PostTypeId = 2
),
RecentPosts AS (
    SELECT 
        p.Id AS RecentPostId,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.UpVotesCount,
    ua.DownVotesCount,
    ua.PostsCount,
    ua.CommentsCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName AS PostOwner,
    aa.IsAccepted,
    rp.OwnerDisplayName AS RecentPostOwner,
    rp.CreationDate AS RecentPostDate,
    rp.RecentPostId
FROM UserActivity ua
LEFT JOIN PostStatistics ps ON ua.UserId = ps.OwnerUserId
LEFT JOIN AcceptedAnswers aa ON ps.PostId = aa.AcceptedAnswerId
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerDisplayName
WHERE (ua.UpVotesCount > 10 OR ua.CommentsCount > 5)
AND (ps.RankByDate <= 5 OR ps.AnswerCount > 3)
ORDER BY ua.DisplayName, ps.CreationDate DESC;
