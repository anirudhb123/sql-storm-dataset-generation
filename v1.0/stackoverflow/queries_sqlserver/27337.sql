
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
TagAnalysis AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p 
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ta.TagName,
    ta.TagCount,
    cp.CreationDate AS ClosedDate,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS ClosureComment,
    cp.PostHistoryType AS ClosureType
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAnalysis ta ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' + ta.TagName + '%')
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankByScore <= 5  
GROUP BY 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ta.TagName,
    ta.TagCount,
    cp.CreationDate,
    cp.UserDisplayName,
    cp.Comment,
    cp.PostHistoryType
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;
