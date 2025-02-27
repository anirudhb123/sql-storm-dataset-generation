WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE()) 
        AND u.Reputation IS NOT NULL
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rn
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate < GETDATE() 
        AND ph.Comment IS NOT NULL
),
CommentSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveComments,
        SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(cs.PositiveComments, 0) AS PositiveComments,
        COALESCE(cs.NegativeComments, 0) AS NegativeComments,
        phd.HistoryType,
        phd.UserDisplayName AS HistoryUser,
        phd.Comment AS HistoryComment,
        phd.HistoryCreationDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentSummary cs ON rp.PostId = cs.PostId
    LEFT JOIN 
        PostHistoryData phd ON rp.PostId = phd.PostId AND phd.history_rn = 1
)
SELECT 
    a.PostId,
    a.Title,
    a.OwnerDisplayName,
    a.OwnerReputation,
    a.CreationDate,
    a.ViewCount,
    a.CommentCount,
    a.PositiveComments,
    a.NegativeComments,
    CASE 
        WHEN a.CommentCount = 0 THEN 'No Comments'
        WHEN a.PositiveComments > a.NegativeComments THEN 'More Positive Comments'
        ELSE 'More Negative Comments'
    END AS CommentAnalysis,
    CASE 
        WHEN a.HistoryType IS NOT NULL THEN CONCAT('Last Edited by ', a.HistoryUser, ' on ', FORMAT(a.HistoryCreationDate, 'yyyy-MM-dd'), ': ', a.HistoryComment) 
        ELSE 'No Edits'
    END AS LastEditDetails
FROM 
    AggregatedData a
WHERE 
    a.ViewCount > 100
ORDER BY 
    a.CreationDate DESC;
