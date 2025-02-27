WITH RECURSIVE PopularPosts AS (
    -- Recursive CTE to find up to 5 most popular answers for each question
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
UserReputation AS (
    -- CTE to find users with more than a certain reputation and their total upvotes
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        SUM(v.VoteTypeId = 2) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        u.Reputation > 1000  -- Only users with above 1000 reputation
),
PostActivity AS (
    -- CTE to find posts with activity in the last year
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        MAX(c.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
PostCloseReasons AS (
    -- CTE to get post close reasons for closed questions
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, '; ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id  -- Assuming Comment holds close reason Ids
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    pp.PostId AS AnswerId,
    pp.Title AS AnswerTitle,
    ur.UserId AS AnswerUserId,
    ur.DisplayName AS AnswerUserName,
    ur.Reputation AS AnswerUserReputation,
    pr.CloseReasons,
    pa.LastActivityDate
FROM 
    Posts p
LEFT JOIN 
    PopularPosts pp ON p.Id = pp.ParentId AND pp.Rank <= 5
LEFT JOIN 
    UserReputation ur ON pp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostActivity pa ON p.Id = pa.PostId
LEFT JOIN 
    PostCloseReasons pr ON p.Id = pr.PostId
WHERE 
    p.PostTypeId = 1  -- Only questions
    AND (pa.LastActivityDate IS NOT NULL OR pr.CloseReasons IS NOT NULL)
ORDER BY 
    p.Score DESC, pp.Score DESC;
