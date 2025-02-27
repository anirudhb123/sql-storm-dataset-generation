WITH RecursivePostCTE AS (
    SELECT 
        Id,
        PostTypeId,
        AcceptedAnswerId,
        Title,
        OwnerUserId,
        CreationDate,
        0 AS Depth
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Start with questions (PostTypeId = 1)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        rp.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
    WHERE 
        p.PostTypeId = 2  -- Only consider answers (PostTypeId = 2)
),
PostMetadata AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- Counting UpVotes
        SUM(v.VoteTypeId = 3) AS DownVotes -- Counting DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Posts ah ON p.AcceptedAnswerId = ah.Id  -- Join to include accepted answer information
    GROUP BY 
        p.Id, p.Title, p.CreationDate, ah.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY pm.Title ORDER BY pm.UpVotes DESC) AS Rank
    FROM 
        PostMetadata pm
    WHERE 
        pm.UpVotes > 10 -- Filter for posts with more than 10 upvotes
)
SELECT 
    t.PostId,
    p.Title,
    p.CreationDate,
    pm.CommentCount,
    t.UpVotes,
    t.DownVotes,
    rpc.Depth,
    CASE 
        WHEN pm.AcceptedAnswerId > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM 
    TopPosts t
JOIN 
    Posts p ON t.PostId = p.Id
JOIN 
    RecursivePostCTE rpc ON p.Id = rpc.Id
LEFT JOIN 
    PostMetadata pm ON p.Id = pm.PostId
WHERE 
    t.Rank = 1  -- Top post per title
ORDER BY 
    p.CreationDate DESC; -- Ordered by date
