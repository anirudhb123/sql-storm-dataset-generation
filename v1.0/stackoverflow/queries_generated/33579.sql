WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
TopAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS AnswerRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
    WHERE 
        p.PostTypeId = 2  -- Answer
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' END) AS IsClosed,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS AuthorName,
    u.Reputation,
    COALESCE(pha.IsClosed, 'Open') AS Status,
    COALESCE(pha.DeletionCount, 0) AS NumberOfDeletions,
    rph.Score AS PostScore,
    COUNT(c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistoryAggregation pha ON p.Id = pha.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON rph.Id = p.Id
WHERE 
    p.PostTypeId IN (1, 2)  -- Questions and Answers
AND 
    u.Reputation > 100  -- Users with more than 100 reputation
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, pha.IsClosed, pha.DeletionCount, rph.Score
HAVING 
    COUNT(c.Id) > 5  -- Posts with more than 5 comments
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
