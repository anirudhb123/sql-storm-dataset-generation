WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::varchar[]) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ft.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredTags ft ON rp.PostId = ft.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
