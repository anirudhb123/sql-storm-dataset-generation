WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph 
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),
FilteredTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', -1), '<', 1) AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    COALESCE(u.UpVotes, 0) AS UpVotes,
    COALESCE(u.DownVotes, 0) AS DownVotes,
    p.Score,
    p.ViewCount,
    pt.HistoryTypes,
    pt.LastHistoryDate,
    CASE 
        WHEN p.Score > 100 THEN 'Highly Scored'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Moderately Scored'
        ELSE 'Low Scored'
    END AS ScoreCategory,
    CASE
        WHEN EXISTS (SELECT 1 FROM Tags t WHERE t.TagName = 'SQL') THEN 'Contains SQL Tag'
        ELSE 'Does not contain SQL Tag'
    END AS SqlTagStatus
FROM 
    RankedPosts p
LEFT JOIN 
    UserVotes u ON p.PostId = u.PostId
LEFT JOIN 
    PostHistories pt ON p.PostId = pt.PostId
WHERE 
    p.Rank <= 10
ORDER BY 
    p.Score DESC, p.CreationDate DESC;

-- Note: This query combines various SQL concepts, such as CTEs, window functions, 
-- COALESCE for handling NULLs, complex CASE statements for categorization, and 
-- filtering based on both post characteristics and user interaction data.
