WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM
        UserStats
),
PostWithTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM
        Posts p
    LEFT JOIN
        UNNEST(string_to_array(p.Tags, ',')) AS tag ON TRUE
    LEFT JOIN
        Tags t ON t.TagName = TRIM(tag)
    GROUP BY
        p.Id
)
SELECT
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    pt.TagCount,
    CASE 
        WHEN pt.TagCount > 10 THEN 'Experienced'
        WHEN pt.TagCount BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Beginner'
    END AS UserCategory
FROM
    TopUsers tu
JOIN
    Posts p ON tu.UserId = p.OwnerUserId
JOIN
    PostWithTagCounts pt ON p.Id = pt.PostId
WHERE
    tu.Rank <= 10
ORDER BY
    tu.Reputation DESC, pt.TagCount DESC;
