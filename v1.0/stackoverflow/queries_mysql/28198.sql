
WITH TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.TotalViews,
        ts.AverageScore,
        @rank := IF(@prevPostCount = ts.PostCount, @rank, @rank + 1) AS TagRank,
        @prevPostCount := ts.PostCount
    FROM 
        TagStatistics ts, (SELECT @rank := 0, @prevPostCount := NULL) r
    ORDER BY 
        ts.PostCount DESC
)
SELECT 
    te.TagName,
    te.PostCount,
    te.QuestionCount,
    te.AnswerCount,
    te.TotalViews,
    te.AverageScore,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalBountySpent,
    ue.UpVotesReceived,
    ue.DownVotesReceived
FROM 
    TopTags te
JOIN 
    UserEngagement ue ON ue.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE CONCAT('%', te.TagName, '%')
    )
WHERE 
    te.TagRank <= 10
ORDER BY 
    te.PostCount DESC, ue.TotalPosts DESC;
