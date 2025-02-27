WITH RecursivePostHierarchy AS (
    -- CTE to recursively get all answers related to each question
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title AS PostTitle,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        rh.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy rh ON a.ParentId = rh.PostId
    WHERE 
        a.PostTypeId = 2 -- Answers only
),
EnhancedUserStats AS (
    -- CTE to gather user statistics along with the count of badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(b.Id) AS BadgeCount,
        AVG(b.Class) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
PostScoreSummary AS (
    -- CTE to calculate scores and trends of questions and answers
    SELECT 
        p.Id AS PostId,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Score
),
AggregateStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
)
SELECT 
    p.PostId,
    p.PostTitle,
    u.DisplayName AS Owner,
    us.Reputation,
    us.BadgeCount,
    ps.CommentsCount,
    ps.VotesCount,
    ps.AvgBounty,
    ph.Level AS AnswerLevel,
    COALESCE(a.Title, 'No Accepted Answer') AS AcceptedAnswerTitle
FROM 
    RecursivePostHierarchy ph
JOIN 
    EnhancedUserStats us ON us.UserId = ph.OwnerUserId
JOIN 
    PostScoreSummary ps ON ps.PostId = ph.PostId
LEFT JOIN 
    Posts a ON a.Id = ph.AcceptedAnswerId
JOIN 
    AggregateStats AS ag ON 1=1 -- To include aggregate stats in the output
WHERE 
    us.Reputation > 100 -- Filter for users with reputation above 100
ORDER BY 
    ph.Level, ps.VotesCount DESC; -- Order by answer level and vote count
