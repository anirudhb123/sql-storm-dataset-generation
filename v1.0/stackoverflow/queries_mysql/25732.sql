
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
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        FilteredPosts p
    CROSS JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(REPLACE(SUBSTRING(p.Body, 2, LENGTH(p.Body) - 2), '><', ','), '>', ''), '<', ''), ',', n.n) AS tags
         FROM (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n) AS tag_list
    JOIN 
        Tags t ON t.TagName = tags
    GROUP BY 
        p.PostId
),
PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT ph.PostHistoryTypeId) AS HistoryTypes,
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
