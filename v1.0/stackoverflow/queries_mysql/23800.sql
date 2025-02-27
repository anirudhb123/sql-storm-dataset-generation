
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        @rownum := IF(@prev_post_type = p.PostTypeId, @rownum + 1, 1) AS RankByDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes, 
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT unnest(string_to_array(p.Tags, '<>,>')) AS TagName FROM Posts p) t ON TRUE,
        (SELECT @rownum := 0, @prev_post_type := NULL) r
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.RankByDate,
    rp.CommentCount,
    rp.NetVotes,
    rp.TagsList,
    cp.ClosedDate,
    cp.ClosedBy,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.RankByDate <= 5 AND cp.ClosedDate IS NOT NULL) OR 
    (rp.NetVotes > 10 AND cp.ClosedDate IS NULL)
ORDER BY 
    CASE WHEN cp.ClosedDate IS NOT NULL THEN 0 ELSE 1 END, 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 50;
