WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, Body, Tags, OwnerDisplayName, CreationDate, Score, CommentCount, BadgeCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
TagsStats AS (
    SELECT 
        unnest(string_to_array(Tags, '>')) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        TopRankedPosts
    GROUP BY 
        TagName
)
SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    trp.CreationDate,
    trp.Score,
    ts.TagName,
    ts.TagUsageCount
FROM 
    TopRankedPosts trp
JOIN 
    TagsStats ts ON ts.TagName = ANY(string_to_array(trp.Tags, '>'))
ORDER BY 
    ts.TagUsageCount DESC, 
    trp.Score DESC;
