WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Only consider upvotes
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Tags, p.OwnerUserId, u.DisplayName
),
TagSummaries AS (
    SELECT 
        unnest(string_to_array(Tags, '<>')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),
CommentAggregation AS (
    SELECT 
        PostId,
        string_agg(Text, ' | ') AS AllComments
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ts.PostCount AS AssociatedTagCount,
    ca.AllComments,
    rp.TagRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TagSummaries ts ON rp.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    CommentAggregation ca ON rp.PostId = ca.PostId
WHERE 
    rp.TagRank <= 5 -- Top 5 posts per tag based on view count
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
