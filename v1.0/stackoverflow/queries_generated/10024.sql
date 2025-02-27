WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, b.Count
),
Benchmark AS (
    SELECT
        COUNT(PostId) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        AVG(CommentCount) AS AvgCommentCount,
        AVG(UpVoteCount) AS AvgUpVoteCount,
        AVG(DownVoteCount) AS AvgDownVoteCount,
        AVG(BadgeCount) AS AvgBadgeCount
    FROM
        PostStats
)

SELECT * FROM Benchmark;
