
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(ROUND(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(v.Id), 0), 2), 0) AS UpvotePercentage,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
), 

TagStats AS (
    SELECT 
        TRIM(TAG) AS TagName,
        COUNT(*) AS PostCount,
        AVG(DATEDIFF(second, CreationDate, '2024-10-01 12:34:56')) AS AvgTimeSinceLastPost
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS TAG
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TAG
),

PopularTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AvgTimeSinceLastPost,
        lt.Name AS LinkTypeName
    FROM 
        TagStats ts
    LEFT JOIN 
        LinkTypes lt ON ts.TagName LIKE '%' || lt.Name || '%' 
    ORDER BY 
        ts.PostCount DESC
    LIMIT 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpvotePercentage,
    pt.TagName,
    pt.PostCount AS TagPostCount,
    pt.AvgTimeSinceLastPost
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON POSITION(pt.TagName IN rp.Tags) > 0
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.CreationDate DESC;
