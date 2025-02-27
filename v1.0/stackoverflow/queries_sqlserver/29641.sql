
WITH TagCounts AS (
    SELECT
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <') 
    WHERE
        PostTypeId = 1 
    GROUP BY
        TRIM(value)
),
RankedTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagCounts
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
        ROW_NUMBER() OVER (ORDER BY UpVotesCount DESC, TotalScore DESC) AS UserRank
    FROM
        UserEngagement
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
