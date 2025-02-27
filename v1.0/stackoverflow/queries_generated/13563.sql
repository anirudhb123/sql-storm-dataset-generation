-- Performance benchmarking query to analyze post statistics and user engagement on Stack Overflow
WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ut.UpVotes, 0) AS UserUpVotes,
        COALESCE(ut.DownVotes, 0) AS UserDownVotes,
        p.Tags,
        ph.PostHistoryTypeId,
        ph.CreationDate AS EditDate
    FROM
        Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT
            UserId,
            SUM(UpVotes) AS UpVotes,
            SUM(DownVotes) AS DownVotes
        FROM
            Users
        GROUP BY UserId
    ) ut ON ut.UserId = u.Id
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE
        p.CreationDate >= '2022-01-01' -- Filter for recent posts

),
AverageStatistics AS (
    SELECT
        AVG(Score) AS AvgScore,
        AVG(ViewCount) AS AvgViewCount,
        AVG(AnswerCount) AS AvgAnswerCount,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(FavoriteCount) AS AvgFavoriteCount
    FROM
        PostStatistics
)

SELECT
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    ps.UserUpVotes,
    ps.UserDownVotes,
    ps.Tags,
    ps.PostHistoryTypeId,
    ps.EditDate,
    avgStats.AvgScore,
    avgStats.AvgViewCount,
    avgStats.AvgAnswerCount,
    avgStats.AvgCommentCount,
    avgStats.AvgFavoriteCount
FROM
    PostStatistics ps,
    AverageStatistics avgStats
ORDER BY
    ps.CreationDate DESC
LIMIT 100; -- Fetch the latest 100 posts with statistics
