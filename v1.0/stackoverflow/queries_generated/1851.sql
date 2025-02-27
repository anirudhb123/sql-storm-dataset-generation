WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserPosts
    WHERE PostCount > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    JOIN PostLinks pl ON pl.RelatedPostId = p.Id
    GROUP BY t.TagName
    HAVING COUNT(pt.Id) > 5
),
CommentStats AS (
    SELECT 
        p.Id AS PostId,
        AVG(c.Score) AS AvgCommentScore,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
)

SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tt.TagName,
    cs.CommentCount,
    cs.AvgCommentScore
FROM TopUsers tu
JOIN PopularTags tt ON tu.UserId = (
    SELECT OwnerUserId
    FROM Posts
    WHERE Tags LIKE '%' + tt.TagName + '%'
    LIMIT 1
)
LEFT JOIN CommentStats cs ON cs.PostId IN (
    SELECT Id
    FROM Posts
    WHERE OwnerUserId = tu.UserId
    LIMIT 5
)
WHERE tu.Rank <= 10
ORDER BY tu.TotalScore DESC, tt.TagCount DESC;
