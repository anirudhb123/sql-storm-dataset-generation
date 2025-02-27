WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(CAST(SUBSTRING(p.Tags FROM 2 FOR CHAR_LENGTH(p.Tags) - 2) AS TEXT[]), ARRAY[]) AS TagArray
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
), 
UserVotingPattern AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        v.PostId
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(CAST(SUBSTRING(p.Tags FROM 2 FOR CHAR_LENGTH(p.Tags) - 2) AS TEXT[]))
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = p.Id)
    WHERE 
        t.IsModeratorOnly = 0
    GROUP BY 
        t.TagName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    cp.CloseReasons,
    uvp.UpVotes,
    uvp.DownVotes,
    uvp.UniqueVoterCount,
    ts.TagName,
    ts.PostCount AS RelatedPostCount,
    ts.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserVotingPattern uvp ON rp.PostId = uvp.PostId
LEFT JOIN 
    TagStats ts ON ts.TagName = ANY(rp.TagArray)
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC, 
    ts.PostCount DESCNULLIF(ts.PostCount, 0) DESC; 

