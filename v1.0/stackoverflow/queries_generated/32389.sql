WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rpc ON p.ParentId = rpc.PostId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, ',')) AS Tag
    FROM 
        Posts p
)
SELECT 
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    t.Tag AS AssociatedTag,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpvotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 10)  -- Keeping upvotes and deletion votes
LEFT JOIN 
    TopUsers u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostTags t ON p.Id = t.PostId
WHERE 
    p.PostTypeId = 1  -- Only Questions
GROUP BY 
    p.Id, t.Tag, u.DisplayName, u.Reputation
HAVING 
    COUNT(c.Id) > 0 AND 
    (COALESCE(SUM(v.BountyAmount), 0) > 0 OR MAX(p.ViewCount) > 100)  -- Filter for popular questions with comments
ORDER BY 
    UserReputation DESC, AVGUpvotes DESC;
