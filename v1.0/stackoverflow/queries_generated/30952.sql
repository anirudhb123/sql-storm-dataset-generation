WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts AS p
    WHERE 
        p.PostTypeId = 1  -- Start with top-level questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts AS p
    INNER JOIN 
        RecursivePostHierarchy AS r ON p.ParentId = r.PostId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS Upvotes,  -- Counting Upvotes
        SUM(v.VoteTypeId = 3) AS Downvotes, -- Counting Downvotes
        COUNT(DISTINCT p.Id) AS PostsCommented
    FROM 
        Users AS u
    LEFT JOIN 
        Comments AS c ON u.Id = c.UserId
    LEFT JOIN 
        Posts AS p ON c.PostId = p.Id
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE 
        u.Reputation > 100  -- Users with reputation more than 100
    GROUP BY 
        u.Id
),

PostVoteHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        COALESCE(COUNT(NULLIF(ph.Comment, '')), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory AS ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Only consider close, reopen, and delete actions
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate, ph.PostHistoryTypeId
)

SELECT 
    p.Title AS QuestionTitle,
    u.DisplayName AS UserName,
    u.Upvotes AS UserUpvotes,
    u.Downvotes AS UserDownvotes,
    u.PostsCommented AS TotalComments,
    COUNT(DISTINCT c.Id) AS TotalCommentsOnPost,
    r.Level AS QuestionLevel,
    COUNT(DISTINCT ph.Id) AS VotesHistoryCount,
    ARRAY_AGG(DISTINCT CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'Deleted'
    END) AS PostHistoryTypes
FROM 
    Posts AS p
LEFT JOIN 
    RecursivePostHierarchy AS r ON p.Id = r.PostId
LEFT JOIN 
    UserReputation AS u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    Comments AS c ON p.Id = c.PostId
LEFT JOIN 
    PostVoteHistory AS ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1  -- Just questions
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Title, u.DisplayName, u.Upvotes, u.Downvotes, u.PostsCommented, r.Level
ORDER BY 
    TotalCommentsOnPost DESC, u.Upvotes DESC
LIMIT 100;
