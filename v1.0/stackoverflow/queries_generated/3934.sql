WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.SomeColumn ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND 
        rp.Score > 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, pht.Name
)
SELECT 
    fp.Title AS PostTitle,
    fp.CreationDate AS PostCreated,
    fp.Score AS PostScore,
    COALESCE(phs.HistoryCount, 0) AS PostHistoryCount,
    (fp.UpVotes - fp.DownVotes) AS NetVotes,
    CASE 
        WHEN fp.Score >= 20 THEN 'High Score'
        WHEN fp.Score >= 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistorySummary phs ON fp.Id = phs.PostId
LEFT JOIN 
    PostLinks pl ON fp.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = fp.Id AND v.VoteTypeId = 10
    )
GROUP BY 
    fp.Title, fp.CreationDate, fp.Score, phs.HistoryCount
ORDER BY 
    fp.Score DESC NULLS LAST;
