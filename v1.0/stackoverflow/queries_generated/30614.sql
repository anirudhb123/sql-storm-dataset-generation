WITH RecursivePostHierarchy AS (
    -- CTE to establish a hierarchy of questions and answers, where
    -- each entry consists of the post and its accepted answers (if any).
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        CAST(p.Title AS VARCHAR(MAX)) AS PostHierarchy
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.PostTypeId,
        a.AcceptedAnswerId,
        a.OwnerUserId,
        CAST(ph.PostHierarchy || ' -> ' || a.Title AS VARCHAR(MAX)) AS PostHierarchy
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy ph ON a.ParentId = ph.PostId
    WHERE 
        a.PostTypeId = 2 -- only answers
),

-- This CTE to extract vote counts per post, distinguishing between upvotes and downvotes
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

-- Aggregate Posts' data with window functions to display ranks based on scores
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.OwnerUserId,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ph.PostHierarchy
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.PostId
)

-- Final selection to join user data and filter ranks, including NULL checks
SELECT 
    u.DisplayName AS Author,
    rp.Title,
    rp.PostRank,
    rp.UpVotes,
    rp.DownVotes,
    rp.PostHierarchy,
    CASE 
        WHEN rp.PostRank IS NULL THEN 'No Posts Found'
        ELSE 'Ranked Post Found'
    END AS Status,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
WHERE 
    rp.PostRank <= 5 -- getting top 5 posts per user
GROUP BY 
    u.DisplayName, rp.Title, rp.PostRank, rp.UpVotes, rp.DownVotes, rp.PostHierarchy
ORDER BY 
    rp.PostRank, u.DisplayName;
