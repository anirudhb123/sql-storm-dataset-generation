WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),

FilteredTopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.VoteCount,
        COALESCE(rp.RankScore, 0) AS RankScore, 
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT STRING_AGG(tag.TagName, ', ') 
         FROM Tags tag
         INNER JOIN Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
         WHERE p.Id = rp.PostId) AS TagsUsed
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
)

SELECT 
    ftp.PostId,
    ftp.Title,
    ftp.ViewCount,
    ftp.Score,
    ft.VoteCount,
    ft.CommentCount,
    ft.TagsUsed,
    ph.HistoryType,
    ph.UserDisplayName,
    ph.CreationDate AS HistoryCreationDate
FROM 
    FilteredTopPosts ftp
LEFT JOIN 
    RecentPostHistory ph ON ftp.PostId = ph.PostId 
WHERE 
    (ph.HistoryRank IS NULL OR ph.HistoryRank = 1)
ORDER BY 
    ftp.Score DESC NULLS LAST, 
    ph.CreationDate DESC NULLS LAST
LIMIT 10;

-- Note: The query retrieves top 5 posts ranked by score within the last year,
-- their most recent activity in the post history from the last 30 days,
-- tags associated with the post, and a count of comments.
