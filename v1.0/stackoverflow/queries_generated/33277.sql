WITH RecursivePostStats AS (
    -- Recursive CTE to calculate Stats for Posts and their Answers
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        p.Score AS PostScore,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        p.Score AS PostScore,
        p.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostStats r ON p.ParentId = r.PostId  -- Get Answers linked to Questions
),
UserStats AS (
    -- CTE to calculate aggregate scores for Users with their post history
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS AnswerScore,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryStats AS (
    -- CTE to analyze post history changes to gather insights
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangesCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on the last year
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
CombinedStats AS (
    -- Combining previous stats for comprehensive results
    SELECT 
        ps.PostId,
        u.UserId,
        u.Reputation,
        u.TotalPosts,
        u.QuestionScore,
        u.AnswerScore,
        COALESCE(p.ChangesCount, 0) AS HistoryChanges,
        COALESCE(p.LastChangeDate, '1970-01-01') AS LastChange
    FROM 
        RecursivePostStats ps
    JOIN 
        UserStats u ON ps.OwnerUserId = u.UserId
    LEFT JOIN 
        PostHistoryStats p ON ps.PostId = p.PostId
),
RankedStats AS (
    -- Ranking users based on their total score from questions and answers
    SELECT 
        *,
        RANK() OVER (ORDER BY (u.QuestionScore + u.AnswerScore) DESC) AS Rank
    FROM 
        CombinedStats u
)

SELECT 
    rs.UserId,
    rs.Reputation,
    rs.TotalPosts,
    rs.QuestionScore,
    rs.AnswerScore,
    rs.HistoryChanges,
    rs.LastChange,
    rs.Rank
FROM 
    RankedStats rs
WHERE 
    rs.Rank <= 10  -- Limit to top 10 users
ORDER BY 
    rs.Rank;
