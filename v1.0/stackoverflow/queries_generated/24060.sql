WITH RecursivePostHistory AS (
    SELECT 
        ph.Id AS PostHistoryId,
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    INNER JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPostHistory AS (
    SELECT 
        rph.PostId,
        COUNT(CASE WHEN rph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN rph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        SUM(CASE WHEN u.Reputation > 500 THEN 1 ELSE 0 END) AS HighRepEditors
    FROM 
        RecursivePostHistory rph
    JOIN 
        Users u ON rph.UserId = u.Id
    WHERE 
        rph.rn <= 5 -- Get last 5 changes per post
    GROUP BY 
        rph.PostId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.CloseCount, 0) AS CloseCount,
        COALESCE(ph.ReopenCount, 0) AS ReopenCount,
        COALESCE(ph.HighRepEditors, 0) AS HighRepEditors,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        FilteredPostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CloseCount,
        ps.ReopenCount,
        ps.HighRepEditors,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS VoteRank
    FROM 
        PostStats ps
)
SELECT 
    rp.Title,
    rp.VoteRank,
    CASE 
        WHEN rp.CloseCount > 0 THEN 'Closed'
        WHEN rp.ReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    rp.CommentCount,
    rp.HighRepEditors,
    STRING_AGG(DISTINCT CONCAT('User: ', u.DisplayName, ' (', u.Reputation, ' Rep)'), '; ') AS HighReputationEditors
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id IN (SELECT DISTINCT UserId FROM PostHistory WHERE PostId = rp.PostId AND PostHistoryTypeId IN (10, 11))
GROUP BY 
    rp.PostId, rp.Title, rp.VoteRank, rp.CloseCount, rp.ReopenCount, rp.CommentCount, rp.HighRepEditors
HAVING 
    rp.ReopenCount < 3
ORDER BY 
    rp.VoteRank, rp.CommentCount DESC;
