WITH RecursivePostCTE AS (
    -- Base case: select all root posts (questions)
    SELECT Id, Title, AcceptedAnswerId, CreationDate, OwnerUserId, Score, 0 AS Level
    FROM Posts
    WHERE PostTypeId = 1

    UNION ALL

    -- Recursive case: join with Posts to find answers to the questions
    SELECT p.Id, p.Title, p.AcceptedAnswerId, p.CreationDate, p.OwnerUserId, p.Score, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE rp ON p.ParentId = rp.Id
    WHERE p.PostTypeId = 2 -- Looking only for answers
),

PostVoteSummary AS (
    -- Calculate total upvotes and downvotes for each post
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),

RecentPostHistory AS (
    -- Get recent edits to posts along with the user who edited them and their badges
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserId,
        ph.Comment,
        u.DisplayName,
        b.Name AS BadgeName
    FROM PostHistory ph
    JOIN Users u ON ph.UserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId AND b.Date = (
        SELECT MAX(Date)
        FROM Badges
        WHERE UserId = u.Id
        GROUP BY UserId
    )
    WHERE ph.CreationDate >= NOW() - INTERVAL '30 days'
),

CombinedSummary AS (
    -- Join CTEs and summarize results
    SELECT
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rv.Upvotes,
        rv.Downvotes,
        rp.Level,
        rph.EditDate,
        rph.DisplayName,
        rph.BadgeName
    FROM RecursivePostCTE rp
    LEFT JOIN PostVoteSummary rv ON rp.Id = rv.PostId
    LEFT JOIN RecentPostHistory rph ON rp.Id = rph.PostId
)

-- Final selection with advanced predicates
SELECT
    c.PostId,
    c.Title,
    c.CreativeDate,
    COALESCE(c.Upvotes, 0) AS TotalUpvotes,
    COALESCE(c.Downvotes, 0) AS TotalDownvotes,
    CASE 
        WHEN c.Level = 0 THEN 'Question'
        ELSE 'Answer'
    END AS PostType,
    c.EditDate,
    COALESCE(c.DisplayName, 'No Editor') AS LastEditedBy,
    COALESCE(c.BadgeName, 'No Badge') AS EditorBadge
FROM CombinedSummary c
WHERE COALESCE(c.Upvotes, 0) - COALESCE(c.Downvotes, 0) > 0 -- Only positive score
AND c.EditDate IS NOT NULL -- Ensuring there's been an edit
ORDER BY c.Upvotes DESC, c.CreationDate DESC
LIMIT 100; -- Limit for performance
