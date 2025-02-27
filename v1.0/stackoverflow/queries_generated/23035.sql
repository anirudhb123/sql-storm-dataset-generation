WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(DATEDIFF('minute', p.CreationDate, COALESCE(p.LastActivityDate, NOW()))) AS AvgPostAge
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LatestEdit,
        MIN(ph.CreationDate) AS FirstEdit,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- EditTitle, EditBody, EditTags
    GROUP BY 
        ph.PostId
),
TagsStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(v.votes) AS TotalVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS votes -- Upvotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    up.DisplayName,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.AvgPostAge,
    ph.EditCount,
    ph.LatestEdit,
    ph.FirstEdit,
    ph.EditComments,
    ts.TagName,
    ts.PostCount,
    ts.TotalVotes
FROM 
    UserPosts up
LEFT JOIN 
    PostHistories ph ON up.UserId = ph.PostId
LEFT JOIN 
    TagsStats ts ON up.TotalPosts > 0 AND ts.PostCount > 0
WHERE 
    (up.TotalPosts > 5 OR up.Reputation > 100)
    AND (up.LastAccessDate IS NOT NULL AND up.LastAccessDate > NOW() - INTERVAL '1 year')
ORDER BY 
    up.AvgPostAge DESC,
    up.TotalPosts DESC,
    ts.TotalVotes DESC
LIMIT 50;

This SQL query accomplishes the following:

1. **Common Table Expressions (CTEs):**
   - `UserPosts` aggregates post statistics for each user, including the total number of questions and answers, as well as average post age.
   - `PostHistories` summarizes the edit history of posts, particularly focusing on the number of edits, the dates of the first and latest edits, and any comments associated with those edits.
   - `TagsStats` provides statistics on tags, including how many posts are associated with each tag and total upvotes received.

2. **Joins:**
   - The main query joins those CTEs to combine user data with their editing activities and tag statistics.

3. **Complicated Conditions:**
   - The `WHERE` clause evaluates users with either more than five posts or a reputation greater than 100, while also ensuring users have accessed their accounts within the last year.

4. **Ordering and Limiting Results:**
   - The results are ordered by average post age, total posts, and tag votes, with a limit on the number of returned rows.

5. **NULL Logic:**
   - Utilizes `COALESCE` to handle `NULL` values, representing cases where posts may not have been edited and ensuring default values are used.

This combination of techniques demonstrates advanced SQL capabilities and is useful for benchmarking SQL generation efficiency.
