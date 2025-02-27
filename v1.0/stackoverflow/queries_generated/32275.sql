WITH RecursivePostHierarchy AS (
    -- CTE to calculate the hierarchy of questions and their respective answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserReputation AS (
    -- CTE to calculate users reputation along with the number of posts they authored
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteStats AS (
    -- CTE to get vote stats per post
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    -- CTE to find closed posts and their reasons
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        MAX(ph.CreationDate) AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId, ph.Comment
),
TopUsers AS (
    -- CTE to find top users based on a running total of their upvotes
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.Upvotes, 0)) AS TotalUpvotes,
        RANK() OVER (ORDER BY SUM(COALESCE(v.Upvotes, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        PostVoteStats v ON u.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rph.PostId AS QuestionId,
    rph.Title AS QuestionTitle,
    u.DisplayName AS Author,
    u.Reputation AS AuthorReputation,
    COALESCE(v.Upvotes, 0) AS TotalUpvotes,
    COALESCE(v.Downvotes, 0) AS TotalDownvotes,
    cp.CloseReason,
    cp.CloseDate,
    tu.Rank AS UserRank
FROM 
    RecursivePostHierarchy rph
JOIN 
    Users u ON rph.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteStats v ON rph.PostId = v.PostId
LEFT JOIN 
    ClosedPosts cp ON rph.PostId = cp.PostId
JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    rph.Level = 0  -- Select only top-level questions
ORDER BY 
    AuthorReputation DESC, 
    TotalUpvotes DESC;
