WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS EffectiveAcceptedAnswerId,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagArray
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostAggregates AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
        LEFT JOIN Comments c ON rp.PostId = c.PostId
        LEFT JOIN Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalPostData AS (
    SELECT 
        pa.PostId,
        rp.Title,
        rp.ViewCount,
        pa.CommentCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        cr.CloseCount,
        cr.ReopenCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId AND b.Class = 1) AS GoldBadgeCount
    FROM 
        PostAggregates pa
        JOIN RankedPosts rp ON pa.PostId = rp.PostId
        LEFT JOIN CloseReasonCounts cr ON pa.PostId = cr.PostId
)
SELECT 
    fpd.PostId,
    fpd.Title,
    fpd.ViewCount,
    fpd.CommentCount,
    fpd.UpVoteCount,
    fpd.DownVoteCount,
    fpd.CloseCount,
    fpd.ReopenCount,
    fpd.GoldBadgeCount,
    ARRAY(SELECT unnest(rp.TagArray) INTERSECT SELECT TagName FROM Tags) AS CommonTags
FROM 
    FinalPostData fpd
JOIN 
    RankedPosts rp ON fpd.PostId = rp.PostId
WHERE 
    fpd.CloseCount = 0 OR fpd.ReopenCount > fpd.CloseCount
ORDER BY 
    fpd.ViewCount DESC, fpd.GoldBadgeCount DESC;
