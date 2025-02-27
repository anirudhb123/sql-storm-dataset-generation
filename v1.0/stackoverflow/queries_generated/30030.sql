WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(4000)) AS FullPath
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
    
    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1,
        CAST(CONCAT(rph.FullPath, ' -> ', p.Title) AS VARCHAR(4000))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers only
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        W.*,
        ROW_NUMBER() OVER (PARTITION BY W.OwnerUserId ORDER BY W.CommentCount DESC) AS OwnerPostRank
    FROM 
        PostStats W
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    rph.Level,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    rp.OwnerPostRank
FROM 
    RecursivePostHierarchy rph
JOIN 
    PostStats ps ON rph.PostId = ps.PostId
JOIN 
    RankedPosts rp ON rph.PostId = rp.PostId
WHERE 
    rph.OwnerUserId IS NOT NULL
    AND rph.Level > 0  -- Exclude root questions
ORDER BY 
    ps.CommentCount DESC, 
    rph.CreationDate DESC
LIMIT 100;
