
WITH TagDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        t.TagName,
        COUNT(*) AS TagUsageCount
    FROM
        Posts p
    INNER JOIN
        Tags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(TRIM(REPLACE(REPLACE(p.Tags, '{', ''), '}', '')), '><'))
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.Tags, t.TagName
),
TopTags AS (
    SELECT
        TagName,
        SUM(TagUsageCount) AS TotalUsage
    FROM
        TagDetails
    GROUP BY
        TagName
    ORDER BY
        TotalUsage DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserScore AS (
    SELECT
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgPostScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 2 
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        DisplayName,
        Upvotes, 
        Downvotes, 
        AnswerCount,
        TotalViews,
        AvgPostScore
    FROM
        UserScore
    ORDER BY 
        Upvotes DESC, 
        AnswerCount DESC 
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT
    tt.TagName,
    tt.TotalUsage,
    tu.DisplayName,
    tu.Upvotes,
    tu.Downvotes,
    tu.AnswerCount,
    tu.TotalViews,
    tu.AvgPostScore
FROM
    TopTags tt
JOIN 
    TopUsers tu ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerDisplayName = tu.DisplayName 
        AND p.Tags LIKE '%' + tt.TagName + '%'
    )
ORDER BY 
    tt.TotalUsage DESC, 
    tu.Upvotes DESC;
