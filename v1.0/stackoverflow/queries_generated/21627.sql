WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserAverages AS (
    SELECT
        u.Id AS UserId,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
TopRankedPosts AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.Score,
        rp.OwnerUserId,
        COALESCE(ua.AvgReputation, 0) AS OwnerAverageReputation
    FROM
        RankedPosts rp
    LEFT JOIN
        UserAverages ua ON rp.OwnerUserId = ua.UserId
    WHERE
        rp.Rank <= 5
),
PostCommentStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments,
        SUM(CASE WHEN c.Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id
)
SELECT
    trp.Title AS TopPostTitle,
    trp.Score AS TopPostScore,
    pc.CommentCount AS TotalComments,
    pc.PositiveComments AS PositiveCommentCount,
    pc.NegativeComments AS NegativeCommentCount,
    CASE
        WHEN trp.OwnerAverageReputation IS NULL THEN 'Unknown'
        WHEN trp.OwnerAverageReputation > 1000 THEN 'Elite'
        ELSE 'Novice'
    END AS OwnerReputationCategory
FROM
    TopRankedPosts trp
JOIN
    PostCommentStats pc ON trp.Id = pc.PostId
WHERE
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = trp.Id
        AND v.VoteTypeId = 2 -- UpMod
        HAVING COUNT(v.Id) > 5
    )
ORDER BY
    trp.Score DESC,
    pc.CommentCount DESC;
This SQL query exemplifies various constructs and features including Common Table Expressions (CTEs), window functions, outer joins, conditional logic, and correlated subqueries. It extracts and ranks posts from the last year, aggregates user averages, computes comment statistics, and categorizes reputation, all while ensuring performance efficiency and semantic depth in the data retrieval process, addressing multiple corner cases like nullability and reputation categorization.
