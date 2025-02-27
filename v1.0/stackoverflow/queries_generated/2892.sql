WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
TagAggregates AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON tag.ExcerptPostId = p.Id
    GROUP BY 
        tag.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.RankScore,
    cp.CloseReason,
    ta.TagName,
    ta.PostCount,
    ta.AvgViewCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    TagAggregates ta ON rp.PostId IN (SELECT unnest(string_to_array(rp.Tags, '><')))
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
