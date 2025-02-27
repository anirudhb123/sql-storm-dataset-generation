WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only select questions
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%') -- Check if the tag is used in posts
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        tag.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5 -- Top 5 most popular tags
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReasonComment,
        ph.UserDisplayName AS CloserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    ORDER BY 
        ph.CreationDate DESC
    LIMIT 10 -- Most recent 10 close reasons
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    pt.TagName AS PopularTag,
    cr.CloseReasonComment,
    cr.CloserDisplayName,
    cr.CreationDate AS CloseDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    RecentCloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.PostRank <= 100 -- Limit to most recent 100 posts
ORDER BY 
    rp.CreationDate DESC, pt.TagCount DESC;

