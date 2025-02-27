WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id
), PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
), PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalComments,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pt.TagName AS PopularTag
FROM UserActivity ua
JOIN PostDetails pd ON ua.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE CreationDate >= NOW() - INTERVAL '6 MONTH')
LEFT JOIN PopularTags pt ON pt.PostCount > 5
WHERE ua.Reputation > 100
ORDER BY ua.Reputation DESC, pd.UpVoteCount DESC
LIMIT 100;
