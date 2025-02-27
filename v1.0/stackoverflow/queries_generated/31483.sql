WITH RecursivePostScores AS (
    SELECT
        p.Id,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1

    UNION ALL

    SELECT
        p.Id,
        ps.Score,
        COALESCE(NULLIF(ps.AcceptedAnswerId, -1), 0),
        Level + 1
    FROM
        Posts ps
    INNER JOIN
        RecursivePostScores rp ON ps.ParentId = rp.Id
)

SELECT
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COUNT(DISTINCT p.Id) AS QuestionsAsked,
    SUM(COALESCE(vt.UpCount, 0)) AS TotalUpvotes,
    SUM(COALESCE(vt.DownCount, 0)) AS TotalDownvotes,
    SUM(COALESCE(vt.NetVotes, 0)) AS NetVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    MAX(p.CreationDate) AS LastPostDate,
    FIRST_VALUE(p.Title) OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS LatestQuestionTitle,
    COUNT(DISTINCT ph.TopicId) AS HistoryChangeCount
FROM
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN (
    SELECT
        p.Id,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) AS NetVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
) vt ON p.Id = vt.Id
LEFT JOIN
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
                       WHERE p.Tags IS NOT NULL)
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened posts
GROUP BY
    u.Id, u.DisplayName, u.Reputation
HAVING
    COUNT(DISTINCT p.Id) > 5
ORDER BY
    u.Reputation DESC, QuestionsAsked DESC
LIMIT 100;

### Explanation:
- **Recursive CTE (`RecursivePostScores`)**: Generates a hierarchy of questions and their accepted answers, potentially useful for hierarchical data analysis.
- **Main Query**: It aggregates user data, counting the number of questions asked, total upvotes, downvotes, net votes, tags used, and history changes.
- **LEFT JOINs**: Utilize various tables to bring together users, their posts, votes on those posts, and tags used.
- **String Functions**: `STRING_AGG` combines tag names into a single string, and `string_to_array` is used to process tags.
- **Window Function**: `FIRST_VALUE` retrieves the latest question title for each user.
- **Complicated Conditions**: The `HAVING` clause filters users who have asked more than 5 questions.
- **Order and Limit**: Finally, the results are ordered by reputation and question count, limited to 100 entries.
