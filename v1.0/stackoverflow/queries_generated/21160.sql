WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
), 
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_AGG(DISTINCT TRIM(Tags.TagName)) AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Tags ON p.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        p.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionUndeletionCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditAppliedTweetedCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    pt.TagList,
    pha.CloseReopenCount,
    pha.DeletionUndeletionCount,
    pha.EditAppliedTweetedCount
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.RN <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

WITH PostStatistics AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LatestCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
), 
PopularTags AS (
    SELECT 
        UNNEST(ARRAY_AGG(DISTINCT TRIM(Tags.TagName))) AS PopularTag
    FROM 
        Tags
    WHERE 
        Count > 10
),
EnhancedPosts AS (
    SELECT 
        p.Id AS PostId,
        ps.CommentCount,
        ps.LatestCommentDate,
        pt.PopularTag
    FROM 
        Posts p
    LEFT JOIN 
        PostStatistics ps ON p.Id = ps.PostId
    LEFT JOIN 
        PopularTags pt ON p.Tags LIKE '%' || pt.PopularTag || '%'
    WHERE 
        p.AcceptedAnswerId IS NULL
)
SELECT 
    ep.PostId,
    COUNT(ep.PopularTag) AS PopularTagCount
FROM 
    EnhancedPosts ep
GROUP BY 
    ep.PostId
HAVING 
    COUNT(ep.PopularTag) > 0
ORDER BY 
    PopularTagCount DESC
FETCH FIRST 50 ROWS ONLY;
