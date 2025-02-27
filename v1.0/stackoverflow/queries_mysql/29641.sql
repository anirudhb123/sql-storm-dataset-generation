
WITH TagCounts AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION 
        SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
RankedTags AS (
    SELECT
        TagName,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM
        TagCounts, (SELECT @rank := 0) r
    ORDER BY
        PostCount DESC
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON v.PostId = p.Id AND v.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionCount,
        TotalViews,
        TotalScore,
        CommentCount,
        UpVotesCount,
        @userRank := @userRank + 1 AS UserRank
    FROM
        UserEngagement, (SELECT @userRank := 0) r
    ORDER BY
        UpVotesCount DESC, TotalScore DESC
)
SELECT
    rt.TagName,
    rt.PostCount,
    tu.DisplayName,
    tu.QuestionCount,
    tu.TotalViews,
    tu.TotalScore,
    tu.CommentCount,
    tu.UpVotesCount
FROM
    RankedTags rt
JOIN 
    TopUsers tu ON rt.Rank <= 10 
ORDER BY
    rt.PostCount DESC,
    tu.UpVotesCount DESC;
