WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        SUM(
            CASE 
                WHEN v.VoteTypeId = 2 THEN 1
                WHEN v.VoteTypeId = 3 THEN -1
                ELSE 0
            END
        ) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        COALESCE(up.Reputation, 0) AS UserReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users up ON rp.OwnerUserId = up.Id
    WHERE 
        rp.Score >= 10 
        OR (rp.CommentCount > 5 AND rp.NetVotes > 0)
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE 
            WHEN pht.Name = 'Post Closed' THEN ph.CreationDate 
            ELSE NULL 
        END) AS LastClosedDate,
        MAX(CASE 
            WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate 
            ELSE NULL 
        END) AS LastReopenedDate,
        MAX(CASE 
            WHEN pht.Name = 'Edit Body' THEN ph.CreationDate 
            ELSE NULL 
        END) AS LastBodyEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UserReputation,
    COALESCE(rph.LastClosedDate, 'Never Closed') AS LastClosed,
    COALESCE(rph.LastReopenedDate, 'Never Reopened') AS LastReopened,
    COALESCE(rph.LastBodyEditDate, 'Never Edited Body') AS LastBodyEdit
FROM 
    FilteredPosts fp
LEFT JOIN 
    RecentPostHistory rph ON fp.PostId = rph.PostId
WHERE 
    (fp.UserReputation > 100 OR fp.CommentCount > 10)
    AND (fp.LastClosed IS NULL OR fp.LastReopened IS NOT NULL)
ORDER BY 
    fp.CommentCount DESC, 
    fp.UserReputation DESC
FETCH FIRST 10 ROWS ONLY

UNION ALL

SELECT 
    -1 AS PostId,
    'Community Contributions' AS Title,
    CURRENT_TIMESTAMP AS CreationDate,
    COUNT(DISTINCT PostId) AS CommentCount,
    SUM(UserReputation) AS UserReputation,
    NULL AS LastClosed,
    NULL AS LastReopened,
    NULL AS LastBodyEdit
FROM 
    Users 
WHERE 
    Reputation > 200
GROUP BY 
    'Community Contributions'

ORDER BY 
    CommentCount DESC;
