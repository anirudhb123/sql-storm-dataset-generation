
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
               FROM Posts p
               INNER JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
                           UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
               ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE p.PostTypeId = 1
    AND p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.*,
        ur.DisplayName AS OwnerDisplayName,
        ur.TotalScore,
        ur.PostsCount,
        ur.BadgesCount
    FROM PostStats ps
    JOIN UserRankings ur ON ps.PostId = ur.UserId
    ORDER BY ps.Score DESC
    LIMIT 10
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    Tags,
    OwnerDisplayName,
    TotalScore,
    PostsCount,
    BadgesCount
FROM TopPosts
ORDER BY Score DESC, CreationDate ASC;
