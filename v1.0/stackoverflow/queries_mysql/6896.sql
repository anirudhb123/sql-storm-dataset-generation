
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned,
        @BountyRank := @BountyRank + 1 AS BountyRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    CROSS JOIN 
        (SELECT @BountyRank := 0) r
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        QuestionsCount, 
        AnswersCount, 
        TotalBountyEarned
    FROM 
        UserActivity
    WHERE 
        BountyRank <= 10
),
MostActivePostTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 AS n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    tc.DisplayName, 
    tc.TotalPosts, 
    tc.QuestionsCount, 
    tc.AnswersCount, 
    tc.TotalBountyEarned,
    mpt.TagName,
    mpt.PostCount
FROM 
    TopContributors tc
CROSS JOIN 
    MostActivePostTags mpt
ORDER BY 
    tc.TotalBountyEarned DESC, mpt.PostCount DESC;
