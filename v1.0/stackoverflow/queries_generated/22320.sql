WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.Tags,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC) AS ScoreRank
    FROM 
        PostDetails pd
    WHERE 
        pd.Score > 0
),
UserWithTopPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.CommentCount,
        tp.Tags
    FROM 
        UserActivity ua
    JOIN 
        TopPosts tp ON tp.CommentCount = (SELECT MAX(CommentCount) FROM TopPosts WHERE ScoreRank <= 5)
    WHERE 
        ua.TotalPosts > 10
)
SELECT 
    u.DisplayName,
    COALESCE(CONCAT('Upvotes: ', CAST(u.Upvotes AS TEXT), ', Downvotes: ', CAST(u.Downvotes AS TEXT)), 'No votes') AS VoteSummary,
    COALESCE(STRING_AGG(CONCAT('Post: ', tp.Title, ' (Score: ', tp.Score, ') - ', tp.Tags), '; ' ORDER BY tp.Score DESC), 'No Posts') AS TopPostDetails
FROM 
    UserActivity u
LEFT JOIN 
    UserWithTopPosts tp ON u.UserId = tp.UserId
GROUP BY 
    u.UserId, u.DisplayName
ORDER BY 
    u.Reputation DESC, u.TotalPosts DESC;

-- Optionally, using a UNION to include users with no posts and their reputation
UNION
SELECT 
    u.DisplayName,
    'No votes' AS VoteSummary,
    'No Posts' AS TopPostDetails
FROM 
    Users u
WHERE 
    u.Id NOT IN (SELECT UserId FROM UserActivity);

This SQL query does the following:

1. CTE `UserActivity` gathers user activity metrics: counting posts and comments, tallying upvotes and downvotes, and ranking users by post activity.
2. CTE `PostDetails` compiles details for posts created in the last month, including titles, scores, and tags.
3. CTE `TopPosts` ranks posts based on scores while including only those with a positive score.
4. CTE `UserWithTopPosts` joins user activity with their top posts, focusing on the top comment counts from the most engaged users.
5. The main SELECT statement combines the data for output, providing a summary of user engagement and their top posts, with careful attention to NULL handling and strings, ensuring to represent users with no post activity using a `UNION`.
  
The use of multiple CTEs, window functions, string aggregation, and conditional aggregation creates a complex yet insightful performance-oriented query.
