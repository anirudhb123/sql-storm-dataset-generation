WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.Score IS NOT NULL
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(c.CommentsAmount, 0)) AS TotalComments,
        SUM(coalesce(b.Class, 0)) AS BadgeScore
    FROM
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentsAmount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON v.PostId = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
ScoreAnalysis AS (
    SELECT
        up.UserId,
        up.DisplayName,
        up.UpVotes,
        up.DownVotes,
        up.TotalComments,
        up.BadgeScore,
        COALESCE(SUM(CASE WHEN rp.Rank <= 3 THEN 1 ELSE 0 END), 0) AS TopThreePosts,
        COALESCE(AVG(rp.Score), 0) AS AvgTopPostScore
    FROM
        UserEngagement up
    LEFT JOIN RankedPosts rp ON up.UserId = p.OwnerUserId
    GROUP BY
        up.UserId, up.DisplayName
)
SELECT
    sa.UserId,
    sa.DisplayName,
    sa.UpVotes,
    sa.DownVotes,
    sa.TotalComments,
    sa.BadgeScore,
    sa.TopThreePosts,
    sa.AvgTopPostScore,
    CASE
        WHEN sa.BadgeScore IS NULL THEN 'No Badges'
        WHEN sa.BadgeScore >= 10 THEN 'Gold Member'
        WHEN sa.BadgeScore >= 5 THEN 'Silver Member'
        ELSE 'Newbie'
    END AS UserRank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM Posts p
            WHERE p.OwnerUserId = sa.UserId AND p.CreationDate > NOW() - INTERVAL '12 months'
              AND p.Title IS NOT NULL 
              AND p.Score > 0
              AND p.Tags LIKE '%SQL%'
        ) THEN 'Active SQL Participant'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM
    ScoreAnalysis sa
WHERE
    sa.UpVotes > sa.DownVotes
ORDER BY
    sa.AvgTopPostScore DESC NULLS LAST, 
    sa.UpVotes DESC, 
    sa.UserRank;
