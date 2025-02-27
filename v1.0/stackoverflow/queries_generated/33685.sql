WITH RecursivePostCTE AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
),
PostVoteAggregates AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COALESCE(pva.UpVotes, 0) AS UpVotes,
    COALESCE(pva.DownVotes, 0) AS DownVotes,
    phc.EditCount,
    phc.LastEditDate,
    rp.Level AS PostLevel,
    ARRAY_AGG(DISTINCT tag.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    PostVoteAggregates pva ON p.Id = pva.PostId
LEFT JOIN 
    PostHistoryCounts phc ON p.Id = phc.PostId
LEFT JOIN 
    RecursivePostCTE rp ON p.Id = rp.Id OR p.ParentId = rp.Id
LEFT JOIN 
    (SELECT 
        Id, UNNEST(string_to_array(Tags, '><')) AS TagName 
     FROM 
        Posts) tag ON tag.Id = p.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, pva.UpVotes, pva.DownVotes, phc.EditCount, phc.LastEditDate, rp.Level
ORDER BY 
    p.CreationDate DESC, UpVotes DESC
LIMIT 100;
