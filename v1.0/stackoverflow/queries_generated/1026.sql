WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostCommentCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)
SELECT 
    u.DisplayName AS User,
    ups.PostId,
    ups.Title,
    ups.CreationDate,
    ups.CommentCount,
    uvs.TotalVotes,
    uvs.UpVotes,
    uvs.DownVotes,
    COALESCE(uvs.TotalVotes / NULLIF(ups.CommentCount, 0), 0) AS VotesPerComment,
    CASE 
        WHEN uvs.VoteRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM UserVoteStatistics uvs
JOIN RecentPosts ups ON uvs.UserId = ups.OwnerUserId
JOIN PostCommentCounts pcc ON ups.PostId = pcc.PostId
WHERE uvs.TotalVotes > 5 
AND ups.RecentPostRank = 1
ORDER BY uvs.TotalVotes DESC, ups.CreationDate DESC;

