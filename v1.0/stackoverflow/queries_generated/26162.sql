WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(uc.UserCount, 0) AS UpVoteCount,
        COALESCE(dc.UserCount, 0) AS DownVoteCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS UserCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 -- Upvote
        GROUP BY 
            PostId
    ) uc ON p.Id = uc.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS UserCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3 -- Downvote
        GROUP BY 
            PostId
    ) dc ON p.Id = dc.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, uc.UserCount, dc.UserCount
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS hist_rn
    FROM 
        PostHistory ph
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.Tags,
    rph.UserDisplayName AS LastEditor,
    rph.HistoryDate,
    rph.Comment AS LastChangeComment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.hist_rn = 1
WHERE 
    rp.ViewCount > 1000 -- Only posts with more than 1000 views
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC -- Ordering by score and then view count
LIMIT 50;

