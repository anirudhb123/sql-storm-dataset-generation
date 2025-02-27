
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        pt.Name AS PostType,
        COALESCE(cht.Name, 'No Close Reason') AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CloseReasonTypes cht ON EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId = 10
        )
    JOIN 
        PostTypes pt ON pt.Id = (SELECT TOP 1 PostTypeId FROM Posts WHERE Id = rp.PostId)
    WHERE
        rp.Rank <= 10
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.PostType,
    pt.TagName AS MostPopularTag
FROM 
    PostDetails pd
JOIN 
    PopularTags pt ON pd.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' + pt.TagName + '%')
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
