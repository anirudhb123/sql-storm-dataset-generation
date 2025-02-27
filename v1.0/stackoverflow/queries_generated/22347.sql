WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(p.Body, ''), '<empty>') AS BodyContent,
        STRING_AGG(t.TagName, ', ') AS TagsAggregated
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM  
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagsAggregated,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(phs.EditCount, 0) AS EditCount,
    PH_CASE WHEN phs.EditCount IS NULL THEN 'No Edits Yet' ELSE 'Edited' END AS EditStatus,
    /* Accumulating a string of all Owners displaying their characteristics */
    (SELECT STRING_AGG(DISTINCT u.DisplayName, ', ' ORDER BY u.Reputation DESC)
     FROM Users u
     WHERE u.Id IN (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
    ) AS OwnersDisplayNames,
    CASE 
        WHEN EXISTS (SELECT 1 FROM PostLinks pl WHERE pl.PostId = rp.PostId) THEN 'Linked to Other Posts'
        ELSE 'No Links'
    END AS LinkStatus,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 1) THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptedStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 100;
