-- Performance benchmarking query for StackOverflow schema
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Count of UpVotes
        SUM(v.VoteTypeId = 3) AS DownVoteCount -- Count of DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
    GROUP BY 
        p.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate
FROM 
    PostSummary ps
LEFT JOIN 
    PostHistorySummary phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.CreationDate DESC;
