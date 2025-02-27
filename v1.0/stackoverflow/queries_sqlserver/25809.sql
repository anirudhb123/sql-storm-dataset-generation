
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM 
        Posts p
    CROSS APPLY (
        SELECT value AS tag_name 
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '> <')
    ) AS tag_name
    JOIN 
        Tags t ON t.TagName = tag_name.tag_name
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        COUNT(*) AS TotalHistoryRecords
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ptc.TagCount, 0) AS TagCount,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(phs.PostHistoryTypes, 'None') AS PostHistoryTypes,
        COALESCE(phs.TotalHistoryRecords, 0) AS TotalHistoryRecords
    FROM 
        Posts p
    LEFT JOIN 
        PostTagCounts ptc ON p.Id = ptc.PostId
    LEFT JOIN 
        PostVoteStats pvs ON p.Id = pvs.PostId
    LEFT JOIN 
        PostHistoryStats phs ON p.Id = phs.PostId
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
)
SELECT 
    PostId,
    Title,
    TagCount,
    UpVotes,
    DownVotes,
    PostHistoryTypes,
    TotalHistoryRecords
FROM 
    FinalStats
ORDER BY 
    UpVotes DESC, 
    TagCount DESC, 
    TotalHistoryRecords DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
