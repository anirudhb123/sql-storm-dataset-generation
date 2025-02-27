WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),

CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),

VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(cc.TotalComments, 0) AS TotalComments,
    COALESCE(vs.Upvotes, 0) AS Upvotes,
    COALESCE(vs.Downvotes, 0) AS Downvotes,
    rp.OwnerDisplayName
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.PostId = cc.PostId
LEFT JOIN 
    VoteStats vs ON rp.PostId = vs.PostId
WHERE 
    rp.PostRank = 1 -- Get the latest post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 10

UNION

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    0 AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    p.OwnerDisplayName
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 2 -- Include only answers
GROUP BY 
    p.Id
HAVING 
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) > 0
ORDER BY 
    Upvotes DESC
LIMIT 5;
