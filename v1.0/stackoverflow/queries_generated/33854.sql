WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get all answers related to each question
    SELECT 
        Id AS PostId, 
        ParentId, 
        OwnerUserId, 
        Title, 
        Score, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
UserReputation AS (
    -- CTE to rank users based on their reputation
    SELECT 
        Id AS UserId,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
PostVoteCount AS (
    -- CTE to count votes per post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Score AS QuestionScore,
    r.CreationDate AS QuestionDate,
    u.Reputation AS UserReputation,
    pv.UpVotes,
    pv.DownVotes,
    COUNT(DISTINCT (CASE WHEN Level > 0 THEN r.PostId END)) AS AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RecursivePostHierarchy r
JOIN 
    UserReputation u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostVoteCount pv ON r.PostId = pv.PostId
LEFT JOIN 
    Posts post ON r.PostId = post.Id
LEFT JOIN 
    Tags t ON post.Tags LIKE '%' || t.TagName || '%'
WHERE 
    r.Level = 0 -- Only consider top-level questions
GROUP BY 
    r.PostId, r.Title, r.Score, r.CreationDate, u.Reputation, pv.UpVotes, pv.DownVotes
ORDER BY 
    UserReputation DESC, QuestionScore DESC
FETCH FIRST 10 ROWS ONLY;
