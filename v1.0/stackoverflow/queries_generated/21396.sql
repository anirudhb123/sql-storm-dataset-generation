WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') OVER (PARTITION BY p.Id) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '>')) AS TagName) t ON true
    WHERE 
        p.CreationDate > '2020-01-01'
        AND (p.AcceptedAnswerId IS NOT NULL OR p.AnswerCount > 0)
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
        AND ph.CreationDate > '2020-01-01'
    GROUP BY 
        ph.PostId, ph.UserDisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
        AND ph.CreationDate > '2020-01-01'
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        ISNULL(ph.EditCount, 0) AS EditCount,
        ISNULL(cl.CloseReason, 'Not Closed') AS CloseReason,
        rp.Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryCTE ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        ClosedPosts cl ON rp.PostId = cl.Id
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    RankByScore,
    EditCount,
    CloseReason,
    Tags
FROM 
    FinalOutput
WHERE 
    (RankByScore <= 5 OR Tags LIKE '%SQL%')
    AND (CloseReason IS NOT NULL OR EditCount > 0)
ORDER BY 
    Score DESC, CreationDate ASC;
