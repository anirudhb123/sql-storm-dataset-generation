
WITH TagUsage AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostsCount
    FROM
        Posts
    JOIN (
        SELECT 
            a.N + b.N * 10 + 1 AS n 
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
        CROSS JOIN 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT
        TagName,
        PostsCount,
        @rownum := IF(@prev_count = PostsCount, @rownum, @rownum + 1) AS Rnk,
        @prev_count := PostsCount
    FROM
        (SELECT @rownum := 0, @prev_count := NULL) r,
        TagUsage
    ORDER BY
        PostsCount DESC
),
ActiveUsers AS (
    SELECT
        *,
        @rownum2 := IF(@prev_totalposts = TotalPosts, @rownum2, @rownum2 + 1) AS Rnk,
        @prev_totalposts := TotalPosts
    FROM
        (SELECT @rownum2 := 0, @prev_totalposts := NULL) r2,
        UserActivity
    WHERE
        TotalPosts > 10
    ORDER BY
        TotalPosts DESC
)
SELECT
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.UpVotesReceived,
    u.DownVotesReceived,
    t.TagName,
    t.PostsCount
FROM
    ActiveUsers u
JOIN
    TopTags t ON t.Rnk <= 5 
ORDER BY
    u.TotalPosts DESC,
    t.PostsCount DESC;
