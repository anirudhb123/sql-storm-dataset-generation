WITH RecursivePosts AS (
    -- Recursive CTE to collect all posts including answers and their hierarchy
    SELECT 
        Id,
        PostTypeId,
        AcceptedAnswerId,
        ParentId,
        Score,
        CreationDate,
        OwnerUserId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with the top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
PostVotes AS (
    -- Getting votes by user for each post
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 END) AS UpvoteCount,  -- Upvotes and Offensive
        COUNT(CASE WHEN v.VoteTypeId IN (3, 12) THEN 1 END) AS DownvoteCount  -- Downvotes and Spam
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    -- Find top users based on Reputation and Activity
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Users with more than 5 posts
)
SELECT 
    rp.Id AS PostId,
    rp.PostTypeId,
    rp.Score AS PostScore,
    COALESCE(pv.UpvoteCount, 0) AS Upvotes,
    COALESCE(pv.DownvoteCount, 0) AS Downvotes,
    tu.DisplayName AS TopUser,
    tu.TotalReputation AS UserReputation,
    rp.CreationDate,
    rp.Level AS PostLevel
FROM 
    RecursivePosts rp
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.Id
WHERE 
    rp.CreationDate >= NOW() - INTERVAL '30 days'  -- Posts within the last month
AND 
    (rp.Score > 10 OR rp.Level = 0)  -- Either high score or original post
ORDER BY 
    rp.Score DESC, 
    tu.TotalReputation DESC;
