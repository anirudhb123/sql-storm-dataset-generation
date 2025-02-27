WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), ClosingHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        cht.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cht ON ph.Comment::int = cht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
), PopularTags AS (
    SELECT 
        t.TagName, 
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.ExcerptPostId = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 5
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(ch.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(ch.CloseReason, 'N/A') AS CloseReason,
    rp.ViewCount,
    rp.CommentCount,
    pt.TagName,
    pt.TotalViews
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosingHistory ch ON rp.PostId = ch.PostId
LEFT JOIN 
    PopularTags pt ON pt.TotalViews = (
        SELECT MAX(TotalViews) FROM PopularTags
    )
WHERE 
    rp.UserPostRank <= 3
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;


