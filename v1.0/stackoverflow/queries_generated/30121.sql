WITH RecursivePostHierarchy AS (
    -- Start with the root questions
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        CAST(NULL AS VARCHAR(MAX)) AS AnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    -- Recursive part to get answers to each question
    SELECT 
        p.ParentId AS QuestionId,
        NULL AS Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.Id AS AnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON r.QuestionId = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Answers
),

-- Get votes and calculate net score per post (votes - downvotes)
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

-- Get user reputations
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
),

-- Final result combining all data from hierarchy, scores, and user reputations
FinalResults AS (
    SELECT 
        r.QuestionId,
        r.Title,
        r.CreationDate,
        ur.DisplayName AS OwnerDisplayName,
        ps.UpVotes,
        ps.DownVotes,
        ps.TotalVotes,
        r.Level,
        CASE 
            WHEN r.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AnswerStatus
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        PostScores ps ON r.QuestionId = ps.PostId
    LEFT JOIN 
        UserReputations ur ON r.OwnerUserId = ur.UserId
)

-- Fetching the final metrics
SELECT 
    QuestionId,
    Title,
    CreationDate,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    TotalVotes,
    Level,
    AnswerStatus
FROM 
    FinalResults
WHERE 
    Level = 1 -- Only top-level questions
    AND UpVotes > DownVotes -- Show only questions where upvotes exceed downvotes
ORDER BY 
    UpVotes DESC, 
    CreationDate DESC
LIMIT 50; -- Get the top 50 questions based on upvotes
