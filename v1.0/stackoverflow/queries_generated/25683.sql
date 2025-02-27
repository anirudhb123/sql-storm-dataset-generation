WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts 
    WHERE Tags IS NOT NULL AND LENGTH(Tags) > 2
    GROUP BY TagName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Tags,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.Questions,
    ua.Answers,
    ua.AcceptedAnswers,
    ua.TotalScore,
    pt.TagName,
    pt.TagCount,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.CreationDate AS TopPostCreationDate
FROM UserActivity ua
LEFT JOIN PopularTags pt ON ua.PostCount > 0 -- Match users who have made posts
LEFT JOIN TopPosts tp ON tp.PostRank <= 10
ORDER BY ua.TotalScore DESC, ua.PostCount DESC, pt.TagCount DESC;
