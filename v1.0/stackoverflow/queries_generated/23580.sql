WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.AnswerCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate,
        ViewCount,
        AnswerCount,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
PostStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN tp.Reputation > 1000 THEN 'High Reputation'
        WHEN tp.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopPosts tp
LEFT JOIN 
    PostStats ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC
LIMIT 10;

-- Subquery to find most common close reasons for posts
SELECT 
    C.Comment, 
    COUNT(*) AS CloseCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
GROUP BY 
    C.Comment
ORDER BY 
    CloseCount DESC
LIMIT 5;

-- Combine data from Posts and PostLinks to find linked posts
SELECT 
    p1.Title AS OriginalPostTitle,
    p2.Title AS RelatedPostTitle,
    pl.CreationDate AS LinkDate,
    lt.Name AS LinkType
FROM 
    PostLinks pl
JOIN 
    Posts p1 ON pl.PostId = p1.Id
JOIN 
    Posts p2 ON pl.RelatedPostId = p2.Id
JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE 
    lt.Name = 'Duplicate'
ORDER BY 
    LinkDate DESC
LIMIT 15;

-- Count of distinct tags used in questions
SELECT 
    COUNT(DISTINCT t.TagName) AS UniqueTagsCount
FROM 
    Tags t
JOIN 
    Posts p ON t.Id = ANY(string_to_array(p.Tags, '<>'))
WHERE 
    p.PostTypeId = 1; -- Only questions
