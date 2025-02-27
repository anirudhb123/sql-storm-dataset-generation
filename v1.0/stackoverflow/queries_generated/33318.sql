WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        Posts parent ON p.ParentId = parent.Id
    WHERE 
        parent.PostTypeId = 2  -- Only considering Answers
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopQuestions AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Score,
        ph.OwnerUserId,
        ps.UpVotes,
        ps.DownVotes
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        PostVoteSummary ps ON ph.PostId = ps.PostId
    WHERE 
        ph.Level = 0  -- Only top-level questions
    ORDER BY 
        ph.Score DESC
    LIMIT 10
)
SELECT 
    uq.Id AS UserId,
    uq.DisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(pq.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pq.DownVotes, 0) AS TotalDownVotes
FROM 
    Users uq
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON uq.Id = b.UserId
LEFT JOIN (
    SELECT 
        ph.OwnerUserId,
        SUM(ph.UpVotes) AS UpVotes,
        SUM(ph.DownVotes) AS DownVotes
    FROM 
        TopQuestions ph
    GROUP BY 
        ph.OwnerUserId
) pq ON uq.Id = pq.OwnerUserId
WHERE 
    uq.Reputation > 100  -- Filter for reputable users
ORDER BY 
    BadgeCount DESC, uq.DisplayName
LIMIT 20;

### Explanation:
1. **Recursive CTE** `RecursivePostHierarchy`: It builds a hierarchy of posts to get the relationship between questions and answers, capturing the level in the hierarchy.
2. **PostVoteSummary**: It summarizes vote counts for each post, counting upvotes and downvotes.
3. **TopQuestions**: This common table expression filters the top 10 questions based on score, incorporating their vote summary.
4. **Final SELECT**: It retrieves users who have a reputation above 100, joining with badge counts and the summarized vote data from top questions. 

The query combines various SQL constructs such as CTEs, joins, and COALESCE to handle NULL values effectively. It showcases different aspects of the data model, including post votes, question-answer relationships, and user reputations.
