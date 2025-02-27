WITH QuestionVotes AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (6, 7)) AS CloseReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
AcceptedAnswers AS (
    SELECT 
        q.Id AS QuestionId,
        a.Id AS AcceptedAnswerId
    FROM 
        Posts q
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
    WHERE 
        q.PostTypeId = 1
),
ActiveUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        p.Id AS RecentPostId,
        p.CreationDate,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    a.AcceptedAnswerId,
    qv.UpVotes,
    qv.DownVotes,
    qv.CloseReopenVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COALESCE(NULLIF(STRING_AGG(r.Title, '; ' ORDER BY r.CreationDate DESC), ''), 'No recent posts') AS RecentPosts,
    CASE 
        WHEN qv.UpVotes > 0 THEN 'Active'
        WHEN qv.CloseReopenVotes > 0 THEN 'Under Review'
        ELSE 'Dormant'
    END AS QuestionStatus
FROM 
    Posts q
LEFT JOIN 
    AcceptedAnswers a ON q.Id = a.QuestionId
JOIN 
    QuestionVotes qv ON q.Id = qv.QuestionId
JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    RecentPosts r ON r.OwnerUserId = q.OwnerUserId AND r.rn <= 5
WHERE 
    q.PostTypeId = 1
    AND (qv.UpVotes - qv.DownVotes) > 0
ORDER BY 
    q.CreationDate DESC
LIMIT 100;

### Explanation:

- **CTEs**:
  - **QuestionVotes**: Aggregates vote counts per question, filtering for specific vote types such as upvotes and close/reopen votes.
  - **AcceptedAnswers**: Joins questions and accepted answers to get the corresponding accepted answers for questions.
  - **ActiveUsers**: Identifies users with reputation over 1000 and assigns them a rank based on their reputation.
  - **RecentPosts**: Retrieves recent posts created in the last 30 days for each user and ranks them.

- **Main SELECT Statement**: 
  - Combines the information across all CTEs, extracting relevant details such as question titles, accepted answer IDs, vote statistics, owner information, and recent posts.
  - Uses `COALESCE` with `STRING_AGG` to handle NULL logic and provide a default message when there are no recent posts.
  - Implements a `CASE` statement for complex predicates to derive the question status based on voting activity.

- **Together**, this query showcases advanced SQL features including window functions, CTEs, aggregate functions, and NULL management, while being structured to highlight performance benchmarking by capturing a range of user and question attributes under specific conditions.
