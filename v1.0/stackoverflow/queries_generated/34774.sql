WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    WHERE 
        CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 10
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
Combined AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        mu.TotalPosts AS ActiveUserTotalPosts,
        pe.EditDate,
        pe.Comment AS LastEditComment,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostActiveUsers mu ON rp.OwnerUserId = mu.OwnerUserId
    LEFT JOIN 
        RecentEdits pe ON rp.PostId = pe.PostId AND pe.EditRank = 1
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    c.PostId,
    c.Title,
    c.ViewCount,
    c.OwnerDisplayName,
    c.ActiveUserTotalPosts,
    c.UpVotes,
    c.DownVotes,
    COALESCE(c.EditDate, 'No edits made') AS LastEditDate,
    COALESCE(c.LastEditComment, 'No comments') AS LastEditComment
FROM 
    Combined c
WHERE 
    COALESCE(c.ActiveUserTotalPosts, 0) > 5
ORDER BY 
    c.ViewCount DESC
LIMIT 50;
