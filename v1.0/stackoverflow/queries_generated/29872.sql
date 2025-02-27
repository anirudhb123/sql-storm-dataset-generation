WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PopularTags AS (
    SELECT 
        UNNEST(SPLIT_PARTS(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10 -- Only tags used more than 10 times
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text AS NewValue,
        p.Title AS PostTitle,
        p.Body AS PostBody
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    pt.TagName,
    pvh.EditDate,
    pvh.UserDisplayName AS Editor,
    pvh.Comment AS EditComment,
    pvh.NewValue AS NewContent
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, '><')) -- Match popular tags
LEFT JOIN 
    PostHistoryDetails pvh ON pvh.PostId = rp.PostId
WHERE 
    rp.TagRank = 1 -- Get the highest-scoring post for each tag
ORDER BY 
    pt.TagCount DESC, 
    rp.Score DESC;
