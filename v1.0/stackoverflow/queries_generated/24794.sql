WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalClosedPosts
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
ActiveUserList AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalClosedPosts,
        ROW_NUMBER() OVER (PARTITION BY (CASE WHEN TotalQuestions > 5 THEN 'HighActivity' ELSE 'LowActivity' END) ORDER BY TotalPosts DESC) AS activity_rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS Tag,
        COUNT(pt.Id) AS TagUsageCount
    FROM 
        Posts p
    JOIN Tags pt ON pt.TagName = ANY(string_to_array(p.Tags, '>'))
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        Tag
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    COALESCE(ROUND((u.TotalAnswers::float / NULLIF(u.TotalQuestions, 0)) * 100, 2), 0) AS AnswerToQuestionRatio,
    GROUP_CONCAT(DISTINCT t.Tag ORDER BY t.TagUsageCount DESC) AS PopularTags,
    CASE 
        WHEN u.TotalClosedPosts > 0 THEN 'Has Closed Posts' 
        ELSE 'No Closed Posts' 
    END AS ClosedPostStatus
FROM 
    ActiveUserList u
LEFT JOIN PopularTags t ON t.Tag IS NOT NULL
WHERE 
    u.activity_rank <= 5
GROUP BY 
    u.UserId, u.DisplayName, u.TotalPosts, u.TotalQuestions, u.TotalAnswers, u.TotalClosedPosts
HAVING 
    AVG(u.TotalPosts) > 2
ORDER BY 
    u.TotalQuestions DESC, 
    u.TotalPosts DESC;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `UserPostStats`: Computes total posts, questions, answers, and closed posts for each user.
   - `ActiveUserList`: Filters users with posts, categorizes them into high and low activity, and ranks them based on the total posts.
   - `PopularTags`: Identifies the most popular tags in posts created in the last 30 days.

2. **Main Query**:
   - Combines data from the `ActiveUserList` and `PopularTags`, providing insights into user activity and popular tags.
   - Calculates the answer-to-question ratio and flags users based on their closed post status.
   - Filters the results based on activity rank and average post count.

3. **Aggregation Functions**:
   - Uses `COALESCE` to handle potential division by zero, and `ROUND` to format the answer-to-question ratio.
   - `GROUP_CONCAT` (or similar) to aggregate tags.

4. **Conditional Logic**:
   - The `CASE` statement to provide feedback on the closed post status.

5. **Predicates and Grouping**:
   - The `HAVING` clause filters to ensure only users with an average post count above a certain threshold are included.

This query serves a dual purpose: showcasing advanced SQL constructs and performing a rich analysis of user engagement within the Stack Overflow schema.
