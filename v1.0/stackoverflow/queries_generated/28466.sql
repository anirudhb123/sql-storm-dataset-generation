WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN (p.AcceptedAnswerId IS NOT NULL AND p.PostTypeId = 1) THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS AssociatedPosts
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag 
    ON 
        tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId IN (1, 2) 
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.WikiCount,
    ups.AcceptedAnswers,
    ups.UpvotedPosts,
    ups.DownvotedPosts,
    at.TagName,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostDate,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViews,
    tp.Author AS TopPostAuthor
FROM 
    UserPostStats ups
LEFT JOIN 
    ActiveTags at ON ups.QuestionCount > 0
LEFT JOIN 
    TopPosts tp ON ups.UserId = tp.Author
WHERE 
    ups.PostCount > 5
ORDER BY 
    ups.Reputation DESC, 
    ups.AcceptedAnswers DESC;
