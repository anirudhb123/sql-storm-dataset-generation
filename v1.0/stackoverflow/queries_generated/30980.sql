WITH RecursivePostHierarchy AS (
    -- Recursive CTE to build a hierarchy of questions and answers
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        a.Id,
        a.Title,
        a.ParentId,
        a.CreationDate,
        a.OwnerUserId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy q ON a.ParentId = q.Id
    WHERE 
        a.PostTypeId = 2  -- Only answers
),
PostViewStats AS (
    -- Summarize view counts and scores of all posts
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS QuestionScores,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    -- Calculate the average reputation of users who posted questions with answers
    SELECT 
        p.OwnerUserId,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        RecursivePostHierarchy p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Level = 1  -- Only take questions
    GROUP BY 
        p.OwnerUserId
),
TagsWithVotes AS (
    -- Get the number of votes by post tags
    SELECT 
        t.TagName,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        t.TagName
),
UserPostStats AS (
    -- Combine all user statistics into one view and rank them
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        vs.TotalViews,
        vs.QuestionScores,
        vs.AnswerCount,
        ur.AvgReputation,
        COALESCE(tv.VoteCount, 0) AS RelatedVoteCount
    FROM 
        Users u
    LEFT JOIN 
        PostViewStats vs ON u.Id = vs.OwnerUserId
    LEFT JOIN 
        UserReputation ur ON u.Id = ur.OwnerUserId
    LEFT JOIN 
        TagsWithVotes tv ON u.Id = tv.TagName  -- This is just a linking for illustrative purposes
)
SELECT 
    UserId,
    DisplayName,
    TotalViews,
    QuestionScores,
    AnswerCount,
    AvgReputation,
    RelatedVoteCount,
    RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
    RANK() OVER (ORDER BY AvgReputation DESC) AS ReputationRank
FROM 
    UserPostStats
WHERE 
    TotalViews IS NOT NULL 
    AND AvgReputation IS NOT NULL
ORDER BY 
    ViewRank, 
    ReputationRank;
