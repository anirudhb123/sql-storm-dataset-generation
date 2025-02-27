WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,  -- Counting Upvotes
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes  -- Counting Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts created in the last year
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- History type indicating a post was closed
    GROUP BY 
        ph.PostId
),
TagDetails AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' + t.TagName + '%'  -- String matching tags
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    cp.FirstClosedDate,
    cp.CloseCount,
    STRING_AGG(td.TagName, ', ') AS Tags,
    CASE 
        WHEN cp.CloseCount > 0 THEN 'Closed' 
        ELSE 'Active' 
    END AS Status
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    TagDetails td ON rp.PostId = td.PostId
WHERE 
    rp.PostRank = 1  -- Get the latest posts for each user
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.UpVotes, rp.DownVotes, cp.FirstClosedDate, cp.CloseCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC  -- Sort by score and view count
OPTION (RECOMPILE);  -- Force recompilation for benchmarking
