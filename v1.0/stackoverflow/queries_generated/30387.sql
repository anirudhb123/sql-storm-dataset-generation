WITH RecursivePostHierarchy AS (
    -- CTE to find all answers to questions, including nested answers
    SELECT 
        Id, 
        ParentId, 
        Title, 
        Score, 
        CreationDate,
        OwnerUserId
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT 
        p.Id, 
        p.ParentId, 
        p.Title, 
        p.Score, 
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2 -- Only Answers
),
TotalVotes AS (
    -- Aggregate votes by PostId for the combined hierarchy
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserAwards AS (
    -- CTE to summarize badges earned by users
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
-- Main query to fetch detailed stats about questions with their answers and user achievements
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.Score AS QuestionScore,
    q.CreationDate AS QuestionCreationDate,
    u.DisplayName AS UserDisplayName,
    COALESCE(tv.UpVotes, 0) - COALESCE(tv.DownVotes, 0) AS NetVotes,
    uaw.GoldBadges,
    uaw.SilverBadges,
    uaw.BronzeBadges,
    COUNT(DISTINCT a.Id) AS AnswerCount,
    STRING_AGG(DISTINCT a.Title, ', ') AS AnswerTitles
FROM 
    RecursivePostHierarchy q
LEFT JOIN 
    RecursivePostHierarchy a ON q.Id = a.ParentId
LEFT JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    TotalVotes tv ON q.Id = tv.PostId
LEFT JOIN 
    UserAwards uaw ON u.Id = uaw.UserId
WHERE 
    q.PostTypeId = 1 -- Filtering to ensure we only consider questions
GROUP BY 
    q.Id, u.DisplayName, tv.UpVotes, tv.DownVotes, uaw.GoldBadges, uaw.SilverBadges, uaw.BronzeBadges
ORDER BY 
    NetVotes DESC, 
    QuestionScore DESC;
