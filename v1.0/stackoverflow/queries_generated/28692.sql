WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
TagsDetail AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
CommentStatistics AS (
    SELECT 
        PostId, 
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.UserDisplayName, ', ') AS CommenterNames
    FROM 
        Comments c
    GROUP BY 
        PostId
),
PostHistoryCount AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    td.TagName,
    td.PostCount,
    td.UserNames AS TaggedUsers,
    cs.CommentCount,
    cs.CommenterNames,
    ph.EditCount
FROM 
    RankedPosts rp
JOIN 
    TagsDetail td ON rp.Tags LIKE '%' || td.TagName || '%'
LEFT JOIN 
    CommentStatistics cs ON rp.PostId = cs.PostId
LEFT JOIN 
    PostHistoryCount ph ON rp.PostId = ph.PostId
WHERE 
    rp.RN = 1  -- Get only the latest post for each tag
ORDER BY 
    rp.CreationDate DESC, 
    td.PostCount DESC;
