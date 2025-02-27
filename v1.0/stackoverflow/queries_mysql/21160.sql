
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS RN,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR)
    ORDER BY p.PostTypeId, p.ViewCount DESC
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
        GROUP_CONCAT(DISTINCT TRIM(Tags.TagName) ORDER BY Tags.TagName SEPARATOR ',') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Tags ON p.Tags LIKE CONCAT('%', Tags.TagName, '%')
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
