WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
),
UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) AS Changes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId, 
        ph.UserId, 
        ph.PostHistoryTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(ph.Id) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Closed posts
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title
)

SELECT 
    u.DisplayName AS Author,
    u.Reputation,
    p.Title AS QuestionTitle,
    COALESCE(rph.PostId, p.Id) AS RelatedPostId,
    COALESCE(rph.Title, 'N/A') AS RelatedTitle,
    COALESCE(phd.Changes, 0) AS EditChanges,
    COALESCE(cp.CloseCount, 0) AS ClosedCount,
    us.Upvotes,
    us.Downvotes,
    us.QuestionCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only questions
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
LEFT JOIN 
    PostHistoryData phd ON p.Id = phd.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.Id
LEFT JOIN 
    UserScoreCTE us ON u.Id = us.UserId
WHERE 
    u.Reputation > 1000  -- Filter users with reputation greater than 1000
ORDER BY 
    u.Reputation DESC, EditChanges DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;  -- Pagination for results
