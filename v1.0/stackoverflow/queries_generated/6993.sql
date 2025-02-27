WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount,
    rp.Rank,
    rp.Tags,
    json_agg(json_build_object(
        'PostHistoryTypeId', phd.PostHistoryTypeId,
        'CreationDate', phd.CreationDate,
        'UserDisplayName', phd.UserDisplayName,
        'HistoryTypes', phd.HistoryTypes
    )) AS PostHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.CommentCount, rp.VoteCount, rp.Rank, rp.Tags
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
