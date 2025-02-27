WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts_Tags pt ON p.Id = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts) 
        AND rp.PostRank = 1
),
ClosedPostsWithReasons AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    hsp.ViewCount,
    hsp.OwnerDisplayName,
    hsp.CommentCount,
    hsp.Tags,
    cpr.CloseReason,
    cpr.ClosedBy
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    ClosedPostsWithReasons cpr ON hsp.PostId = cpr.PostId
ORDER BY 
    hsp.Score DESC, 
    hsp.CommentCount DESC;

