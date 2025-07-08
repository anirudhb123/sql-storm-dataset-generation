
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01' AND p.PostTypeId = 1
),
PostTags AS (
    SELECT 
        p.PostId,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        FilteredPosts p,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(p.Body, 2, LENGTH(p.Body) - 2), '><')) AS tags
    JOIN 
        Tags t ON t.TagName = tags.VALUE
    GROUP BY 
        p.PostId
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ph.PostHistoryTypeId) AS HistoryTypes,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    pt.Tags,
    pha.HistoryTypes,
    pha.RevisionCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTags pt ON fp.PostId = pt.PostId
LEFT JOIN 
    PostHistoryAggregation pha ON fp.PostId = pha.PostId
ORDER BY 
    fp.CreationDate DESC;
