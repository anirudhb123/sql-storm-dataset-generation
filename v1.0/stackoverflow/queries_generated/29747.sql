WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        STUFF(
            (SELECT ', ' + t.TagName
             FROM Tags t
             WHERE t.Id IN (
                 SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
             )
             FOR XML PATH('')), 1, 2, '') AS TagList
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
)

SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.Views,
    ur.QuestionCount,
    ur.TotalScore,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagList
FROM UserReputation ur
JOIN RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE rp.Rank <= 5 -- Retrieve top 5 latest questions per user
ORDER BY ur.QuestionCount DESC, ur.TotalScore DESC, rp.CreationDate DESC;

This SQL query accomplishes the following tasks:

1. **RankedPosts CTE**: Generates a list of posts categorized as questions (PostTypeId = 1), ranked by the creation date for each user, and also creates a comma-separated list of tags for each post.

2. **UserReputation CTE**: Aggregates user data, including overall reputation and views, counts how many questions they've posted, and sums the scores of their posts.

3. **Final Selection**: Joins the two CTEs to provide detailed information about the top 5 latest questions for each user, alongside their display name, reputation score, views, and total question count, sorted primarily by the number of questions, then by total score, and finally by the creation date of the posts.
