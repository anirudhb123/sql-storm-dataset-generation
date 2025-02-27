WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, u.DisplayName
),

RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ra.EditCount,
    ra.LastEditDate,
    CASE 
        WHEN ra.LastEditDate IS NOT NULL AND ra.LastEditDate > rp.CreationDate THEN 'Recently Edited'
        ELSE 'No Recent Edits' 
    END AS EditStatus,
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = rp.PostId AND v.VoteTypeId = 1
    ) AS HasAcceptedAnswer

FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    rp.Rank <= 5  -- Top 5 ranking per author
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;  -- Order results by Score then by CreationDate
This query demonstrates several advanced SQL concepts, including Common Table Expressions (CTEs), window functions, subqueries, outer joins, and CASE statements, creating a comprehensive performance benchmark against the Stack Overflow schema. The resulting output includes insights on top questions, authors, engagement metrics, and recent edits.
