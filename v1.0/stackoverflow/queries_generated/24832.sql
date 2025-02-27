WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(u.UpVotes, 0) AS UpVotes,
    COALESCE(u.DownVotes, 0) AS DownVotes,
    COALESCE(u.PostCount, 0) AS TotalPosts,
    COALESCE(u.QuestionCount, 0) AS TotalQuestions,
    COALESCE(u.AnswerCount, 0) AS TotalAnswers,
    COALESCE(b.Badges, 'None') AS BadgeList,
    rp.PostId,
    rp.Title,
    rp.LastActivityDate
FROM 
    UserVoteSummary u
LEFT JOIN 
    BadgeSummary b ON u.UserId = b.UserId
LEFT JOIN 
    RecentPostActivity rp ON u.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    (u.UpVotes - u.DownVotes) > 5
    AND u.PostCount > 10
    AND u.DisplayName IS NOT NULL
ORDER BY 
    TotalPosts DESC, UpVotes DESC
LIMIT 100;

### Explanation:
1. **CTEs**:
   - `UserVoteSummary`: Aggregates upvotes, downvotes, and post counts per user.
   - `RecentPostActivity`: Retrieves the most recent post activity with row numbering.
   - `BadgeSummary`: Consolidates badge data into a string for each user.

2. **LEFT JOIN**: Utilizes LEFT JOINs to combine user vote details, badge information, and recent activity.

3. **Correlated Subqueries and Window Functions**:
   - ROW_NUMBER used in `RecentPostActivity` assigns a rank to posts which allows only the most recent post to be selected.

4. **Complex Conditions**: Criteria in the WHERE clause necessitates that the user's upvotes exceed their downvotes by a significant margin, and that they have a minimum number of total posts.

5. **String Aggregation**: The `STRING_AGG` function collects all badge names into a single string.

6. **Ordering and Limiting**: Results are sorted primarily by the total number of posts and then by upvotes, limiting the result to the top 100 users satisfying the criteria. 

This query combines various SQL constructs to benchmark performance effectively across diverse user activities and how they correlate to their portrayal in the system, allowing for a deep dive into user contributions in a Stack Overflow-like schema.
