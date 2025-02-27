WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerName,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),

RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)  -- Title edit, body edit, tag edit, closed, reopened
    GROUP BY 
        p.Id
),

AggregatedScores AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (4, 12) THEN 1 ELSE 0 END) AS OffensiveVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    rp.OwnerName,
    ra.LastEditDate,
    ag.UpVotes,
    ag.DownVotes,
    ag.OffensiveVotes,
    CASE 
        WHEN ra.LastEditDate IS NULL THEN 'No edits yet'
        ELSE 'Edited'
    END AS EditStatus,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments c 
     WHERE 
        c.PostId = rp.PostId) AS TotalComments
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON ra.PostId = rp.PostId
LEFT JOIN 
    AggregatedScores ag ON ag.PostId = rp.PostId
WHERE 
    rp.RN = 1 -- Get only the most recent post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;

-- Additionally, let's say we want to check for posts that have been linked to, including their titles
SELECT DISTINCT 
    p.Id AS PostId,
    p.Title AS OriginalPostTitle,
    lp.RelatedPostId,
    rp.Title AS RelatedPostTitle
FROM 
    PostLinks lp
JOIN 
    Posts p ON lp.PostId = p.Id
LEFT JOIN 
    Posts rp ON lp.RelatedPostId = rp.Id
WHERE 
    lp.LinkTypeId IN (1, 3) 
    AND p.CreationDate < CURRENT_DATE - INTERVAL '1 YEAR'  -- Old posts linked
ORDER BY 
    p.CreationDate DESC;
