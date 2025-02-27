WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PotTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount IS NOT NULL 
        AND p.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.PostTypeId, p.Score, p.ViewCount
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        postId,
        COUNT(CASE WHEN postHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReasons,
        COUNT(CASE WHEN postHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory
    GROUP BY 
        postId
)
SELECT 
    p.Title,
    p.Body,
    p.CreationDate,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    COALESCE(ph.CloseReasons, 0) AS TotalCloseReasons,
    COALESCE(ph.DeleteUndeleteCount, 0) AS TotalDeleteUndelete
FROM 
    Posts p
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
LEFT JOIN 
    PostHistoryStats ph ON p.Id = ph.postId
WHERE 
    p.PostTypeId = 1 
    AND p.Score > 0 
    AND (rp.Rank <= 10 OR rv.UpVotes > rv.DownVotes)
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
