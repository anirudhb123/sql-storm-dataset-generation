WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.OwnerUserId) AS UserUpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.OwnerUserId) AS UserDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.TagRank,
    COALESCE(rp.UserUpVotes, 0) AS UpVotes,
    COALESCE(rp.UserDownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank <= 5 OR rp.OwnerUserId IS NULL
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

WITH PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.AskedBy AS Owner,
    COALESCE(phs.FirstClosedDate, 'Never Closed') AS FirstClose,
    phs.CloseCount AS TotalCloses,
    phs.LastEditDate
FROM 
    Posts p
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
WHERE 
    phs.CloseCount > 0 OR p.Score < 0
ORDER BY 
    phs.TotalCloses DESC, p.Score ASC;

SELECT 
    p.Title,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
WHERE 
    p.CommentCount > 0
GROUP BY 
    p.Title
HAVING 
    COUNT(DISTINCT t.TagName) >= 3
ORDER BY 
    COUNT(DISTINCT t.TagName) DESC;

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(vb.BountyAmount, 0)) AS TotalBounty
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes vb ON vb.PostId = p.Id AND vb.VoteTypeId = 8
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    TotalBounty DESC;
