WITH RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(DATEDIFF(second, p.CreationDate, p.LastActivityDate)) AS AvgActivityDuration,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.LastAccessDate DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 1000 AND 
        u.LastAccessDate > DATEADD(day, -30, GETDATE())
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL
),
ConsolidatedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.Body, 'No Content') AS PostBody,
        COALESCE(h.Comment, 'No Comments') AS LastEditComment,
        MAX(COALESCE(V.UserId, -1)) AS VoterId,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId AND h.PostHistoryTypeId IN (5, 6)  -- Edit Body and Tags
    LEFT JOIN 
        Votes V ON p.Id = V.PostId AND V.VoteTypeId = 2 -- UpMods
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Body, h.Comment, p.CreationDate, p.AnswerCount, p.CommentCount
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.PostCount,
    r.QuestionCount,
    r.AnswerCount,
    r.AvgActivityDuration,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.PostBody,
    pp.LastEditComment,
    pp.ViewCount AS PostViewCount,
    pp.CommentCount AS PostCommentCount
FROM 
    RecentUserActivity r
JOIN 
    TopUserPosts pp ON r.UserId = pp.OwnerDisplayName
WHERE 
    pp.PostRank < 6 AND  -- Top 5 posts
    r.UserRank = 1  -- Only the most recently active user
ORDER BY 
    r.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

This elaborate SQL query achieves several tasks:
1. It utilizes Common Table Expressions (CTEs) to structure data into logical sections, namely "RecentUserActivity," "TopUserPosts," and "ConsolidatedPostData."
2. It employs complex aggregations and window functions to compute metrics like average activity duration, user ranks, and post scores.
3. It incorporates outer joins to connect users with their posts while considering the absence of activity or posts.
4. It uses `COALESCE` for potential NULL conditions to ensure smoother reporting.
5. It applies filtering logic to capture only the top activity and recent posts. 
6. Finally, it retrieves a limited set of results using `OFFSET` and `FETCH` for pagination, sorting users by reputation. 

This query serves as an excellent performance benchmark with its complexity and depth, showcasing different SQL constructs and semantics.
