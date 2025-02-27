WITH RECURSIVE PostHierarchy AS (
    -- Base case: select all posts and their corresponding accepted answers
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- only questions
    UNION ALL
    -- Recursive case: join to get answers for each question
    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.PostTypeId,
        a.AcceptedAnswerId,
        a.OwnerUserId,
        ph.Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2 -- only answers
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        ph.PostId,
        ph.PostTitle,
        ph.Depth,
        ph.Score,
        u.DisplayName AS OwnerName,
        ua.QuestionsAsked,
        ua.AnswersGiven,
        ua.TotalVotes
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Users u ON ph.OwnerUserId = u.Id
    LEFT JOIN 
        UserActivity ua ON u.Id = ua.UserId
)
SELECT 
    ps.PostId,
    ps.PostTitle,
    ps.Depth,
    ps.Score,
    ps.OwnerName,
    ps.QuestionsAsked,
    ps.AnswersGiven,
    ps.TotalVotes,
    -- Utilizing a window function to rank posts by score across different depths
    RANK() OVER (PARTITION BY ps.Depth ORDER BY ps.Score DESC) AS RankByScoreDepth,
    -- A complicated predicate to check view status
    CASE 
        WHEN ps.Depth = 1 AND ps.Score >= 10 THEN 'Hot Question' 
        WHEN ps.Depth = 2 AND ps.Score < 5 THEN 'Low Engagement' 
        ELSE 'Moderate' 
    END AS EngagementLevel
FROM 
    PostStatistics ps
ORDER BY 
    ps.Depth, ps.Score DESC;
