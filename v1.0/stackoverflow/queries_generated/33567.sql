WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        r.Level + 1,
        CAST(r.Path + ' -> ' + p2.Title AS VARCHAR(MAX))
    FROM 
        Posts p2
    INNER JOIN 
        Posts p ON p2.ParentId = p.Id
    INNER JOIN 
        RecursivePostHierarchy r ON r.PostId = p.Id
    WHERE 
        p2.PostTypeId = 2  -- Answers
),

AggregatedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Comments c ON c.PostId = ph.PostId
    LEFT JOIN 
        Votes v ON v.PostId = ph.PostId
    GROUP BY 
        ph.PostId
),

FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerName,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.LastActivityDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        AggregatedPostStats ps ON ps.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '7 days'  -- Posts created in the last week
        AND ps.CommentCount > 0  -- Only include posts with comments
)

SELECT 
    fp.Title,
    fp.OwnerName,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    ROW_NUMBER() OVER (ORDER BY fp.UpVoteCount DESC) AS Rank
FROM 
    FilteredPosts fp
ORDER BY 
    Rank
FETCH FIRST 10 ROWS ONLY;  -- Return top 10 posts

