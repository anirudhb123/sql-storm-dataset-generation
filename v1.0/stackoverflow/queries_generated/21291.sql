WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        v.VoteTypeId,
        v.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        v.VoteTypeId IN (2, 3) -- Considering only UpMod and DownMod
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        SUM(vt.VoteTypeId = 2) - SUM(vt.VoteTypeId = 3) AS NetVotes, -- Upvotes - Downvotes
        COALESCE(MAX(b.Date), '1970-01-01') AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    LEFT JOIN 
        Votes vt ON vt.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId 
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.HistoryCount,
    ps.NetVotes,
    COALESCE(ur.TotalReputation, 0) AS UserReputation,
    CASE 
        WHEN ps.CommentCount = 0 THEN 'No Comments'
        WHEN ps.NetVotes > 0 THEN 'Positive'
        WHEN ps.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral' 
    END AS VoteStatus,
    EXTRACT(YEAR FROM ps.LastBadgeDate) AS LastBadgeYear,
    CASE 
        WHEN ps.HistoryCount > 10 THEN 'Highly Edited'
        ELSE 'Few Edits' 
    END AS EditFrequency
FROM 
    PostStats ps
LEFT JOIN 
    UserReputation ur ON ur.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = ps.PostId)
WHERE 
    ps.CommentCount > 5 
    OR ps.NetVotes <> 0 
ORDER BY 
    ps.NetVotes DESC,
    ps.CommentCount DESC;

-- Adding complexity with outer joins and unusual predicates:
-- Include posts that have never been edited OR are from users with less than 1000 reputation
WITH PostsWithEditInfo AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id 
    GROUP BY 
        p.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(pe.EditCount, 0) AS EditCount,
    CASE 
        WHEN pe.EditCount IS NULL THEN 'Never Edited'
        WHEN pe.EditCount > 0 THEN 'Edited'
        ELSE 'Uncertain' 
    END AS EditStatus
FROM 
    Posts p
LEFT JOIN 
    PostsWithEditInfo pe ON p.Id = pe.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation < 1000 
    OR pe.EditCount IS NULL 
ORDER BY 
    u.Reputation ASC, 
    pe.EditCount DESC;
