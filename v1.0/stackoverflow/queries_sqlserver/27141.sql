
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
TagAggregation AS (
    SELECT 
        LTRIM(RTRIM(REPLACE(REPLACE(value, '<', ''), '>', ''))) AS Tag,
        COUNT(*) AS PostCount,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><') AS value
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        LTRIM(RTRIM(REPLACE(REPLACE(value, '<', ''), '>', '')))
),
CommentsAggregation AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    ta.PostCount AS TagUsageCount,
    ta.AverageScore AS TagAverageScore,
    ta.TotalViews AS TagTotalViews,
    ca.TotalComments AS PostTotalComments,
    ca.LastCommentDate AS PostLastCommentDate
FROM 
    RankedPosts rp
JOIN 
    TagAggregation ta ON rp.Tags LIKE '%' + ta.Tag + '%'
LEFT JOIN 
    CommentsAggregation ca ON rp.Id = ca.PostId
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    rp.CreationDate DESC;
