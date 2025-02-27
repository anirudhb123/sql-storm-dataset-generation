WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of posts (questions and their answers)
    SELECT 
        Id,
        ParentId,
        Title,
        OwnerUserId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
    WHERE 
        p.PostTypeId = 2 -- Only answers
),
UserScores AS (
    -- CTE to calculate user scores based on votes and reputation
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostScore AS (
    -- CTE to calculate total score of posts based on votes and accepted status
    SELECT 
        p.Id,
        p.Score + COALESCE(v.UpVoteCount, 0) - COALESCE(v.DownVoteCount, 0) AS TotalScore,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
)
-- Main query to pull together all the information
SELECT 
    q.Title AS QuestionTitle,
    q.CreationDate AS QuestionDate,
    COUNT(a.Id) AS AnswerCount,
    COALESCE(us.UserId, 0) AS UserId,
    us.UpVoteCount,
    us.DownVoteCount,
    us.TotalBounty,
    ps.TotalScore AS PostScore,
    CASE 
        WHEN ps.TotalScore > 10 THEN 'High Engagement'
        WHEN ps.TotalScore BETWEEN 1 AND 10 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts q
LEFT JOIN 
    Posts a ON q.Id = a.ParentId AND a.PostTypeId = 2 -- Answers
LEFT JOIN 
    UserScores us ON q.OwnerUserId = us.UserId
LEFT JOIN 
    PostScore ps ON q.Id = ps.Id
LEFT JOIN 
    unnest(string_to_array(q.Tags, '><')) AS tag(tag_name) ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag.tag_name
WHERE 
    q.PostTypeId = 1
GROUP BY 
    q.Id, us.UserId, ps.TotalScore
ORDER BY 
    PostScore DESC, AnswerCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
