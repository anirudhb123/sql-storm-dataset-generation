WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
),
VoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(vc.UpVotes, 0) AS UpVoteCount,
    COALESCE(vc.DownVotes, 0) AS DownVoteCount,
    us.UserId,
    us.BadgeCount,
    us.NetVotes,
    us.CommentCount AS UserCommentCount,
    CASE 
        WHEN rp.Score > 10 THEN 'Hot'
        WHEN rp.Score > 0 THEN 'Popular'
        ELSE 'Normal' 
    END AS Popularity
FROM RankedPosts rp
LEFT JOIN UserStats us ON us.UserId = rp.PostId
LEFT JOIN VoteCounts vc ON vc.PostId = rp.PostId
WHERE rp.Rank <= 5
ORDER BY rp.CreationDate DESC
UNION ALL
SELECT 
    NULL AS PostId,
    'Summary' AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS AnswerCount,
    NULL AS CommentCount,
    SUM(COALESCE(vc.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(vc.DownVotes, 0)) AS TotalDownVotes,
    NULL AS UserId,
    NULL AS BadgeCount,
    NULL AS NetVotes,
    NULL AS UserCommentCount,
    'Overall' AS Popularity
FROM VoteCounts vc
JOIN Posts p ON vc.PostId = p.Id
WHERE p.CreationDate >= NOW() - INTERVAL '1 year';
