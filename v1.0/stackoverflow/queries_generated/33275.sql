WITH RecursiveCTE AS (
    SELECT 
        Id, 
        PostTypeId, 
        Score, 
        OwnerUserId, 
        Title, 
        CreationDate, 
        ViewCount, 
        CAST(1 AS INT) AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        p.Id, 
        p.PostTypeId, 
        p.Score, 
        p.OwnerUserId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        rc.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE rc ON p.ParentId = rc.Id
    WHERE 
        p.PostTypeId = 2 -- Join with Answers
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstChangeDate,
        MAX(ph.CreationDate) AS LastChangeDate,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) -- Title edits, Body edits, Suggested Edits
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        r.Id AS PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(p.FirstChangeDate, 'No Changes') AS FirstChangeDate,
        COALESCE(p.LastChangeDate, 'No Changes') AS LastChangeDate,
        COALESCE(p.ChangeCount, 0) AS ChangeCount,
        r.Level
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        VoteStats v ON r.Id = v.PostId
    LEFT JOIN 
        PostHistoryInfo p ON r.Id = p.PostId
),
RankedResults AS (
    SELECT 
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f.Level ORDER BY f.Score DESC) AS RankByScore
    FROM 
        FinalStats f
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.UpVotes,
    r.DownVotes,
    r.FirstChangeDate,
    r.LastChangeDate,
    r.ChangeCount,
    r.RankByScore
FROM 
    RankedResults r
WHERE 
    r.RankByScore <= 10 -- Top 10 per level
ORDER BY 
    r.Level, r.Score DESC;
