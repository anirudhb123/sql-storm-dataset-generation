WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND (p.Score IS NOT NULL OR p.ViewCount > 0)
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Rank,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Popular'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Unpopular'
            ELSE 'Neutral'
        END AS Popularity
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 OR 
        (rp.Rank > 10 AND rp.ViewCount > 50)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.CreationDate,
        fp.ViewCount,
        fp.AnswerCount,
        fp.Popularity,
        cp.Comment AS CloseReason,
        cp.UserDisplayName AS ClosedBy
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        ClosedPosts cp ON fp.PostId = cp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.CreationDate,
    fr.ViewCount,
    fr.AnswerCount,
    fr.Popularity,
    COALESCE(fr.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(fr.ClosedBy, 'N/A') AS ClosedBy
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, 
    fr.ViewCount DESC;
