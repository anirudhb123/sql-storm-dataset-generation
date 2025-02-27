WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only include Questions
),
TagStatistics AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        AVG(CommentCount) AS AverageComments
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tags
), 
RecentPostUpdates AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS UpdateDate,
        ph.UserDisplayName,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastUpdateDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    ts.TotalViews,
    ts.PostCount,
    ts.TotalAnswers,
    ts.AverageComments,
    rpu.UserDisplayName AS LastEditor,
    rpu.UpdateDate,
    rpu.LastUpdateDate
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.Tags = ts.Tags
LEFT JOIN 
    RecentPostUpdates rpu ON rp.PostId = rpu.PostId
WHERE 
    rp.TagRank <= 5 -- Limit to top 5 posts per tag based on creation date
ORDER BY 
    rp.Tags, rp.CreationDate DESC;
