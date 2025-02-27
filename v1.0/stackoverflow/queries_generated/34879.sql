WITH RecursivePostChain AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting from top-level posts

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        rpc.Level + 1,
        CAST(rpc.Path + ' -> ' + p2.Title AS VARCHAR(MAX))
    FROM 
        Posts p2
    JOIN 
        RecursivePostChain rpc ON p2.ParentId = rpc.PostId
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ut.DisplayName, 'Anonymous') AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users ut ON p.OwnerUserId = ut.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_SPLIT(p.Tags, ', ') AS t ON t.Value IS NOT NULL
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, ut.DisplayName
),

PostHistoryAgg AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.OwnerName,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.Tags,
    COALESCE(pha.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(pha.DeleteUndeleteCount, 0) AS DeleteUndeleteCount,
    rpc.Level,
    rpc.Path
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryAgg pha ON pd.PostId = pha.PostId
LEFT JOIN 
    RecursivePostChain rpc ON pd.PostId = rpc.PostId
ORDER BY 
    pd.ViewCount DESC,
    pd.UpVotes DESC,
    pd.CommentCount DESC;
