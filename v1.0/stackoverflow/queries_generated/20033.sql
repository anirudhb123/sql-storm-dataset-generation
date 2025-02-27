WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS NetScore,
        100.0 * SUM(v.VoteTypeId = 2) / NULLIF(COUNT(v.Id), 0) AS UpVotePercentage
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.RankByViews,
        rp.NetScore,
        rp.UpVotePercentage,
        COALESCE(oh.Title, 'N/A') AS Original_Title,
        COALESCE(oh.CreationDate, '2020-01-01') AS Original_CreationDate,
        CASE 
            WHEN rp.UpVotePercentage IS NULL THEN 'No Votes Yet' 
            WHEN rp.UpVotePercentage < 50 THEN 'Needs More Love'
            ELSE 'Well Loved'
        END AS Popularity_Status
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            p.Id, p.Title, p.CreationDate
        FROM 
            Posts p 
        WHERE 
            p.PostTypeId = 1 
            AND DATEDIFF(day, p.CreationDate, GETDATE()) > 30) oh ON rp.PostId = oh.Id
    WHERE 
        rp.NetScore >= 0
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.CreationDate,
    pd.RankByViews,
    pd.NetScore,
    pd.UpVotePercentage,
    pd.Original_Title,
    pd.Original_CreationDate,
    pd.Popularity_Status,
    SUM(CASE WHEN ch.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS Closure_Reopen_Count,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Associated_Tags
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId
LEFT JOIN 
    Tags t ON ',' + pd.Tags + ',' LIKE '%,' + CAST(t.Id AS varchar) + ',%'
LEFT JOIN 
    PostHistoryTypes ch ON ph.PostHistoryTypeId = ch.Id
GROUP BY 
    pd.PostId, pd.Title, pd.ViewCount, pd.CreationDate, pd.RankByViews, 
    pd.NetScore, pd.UpVotePercentage, pd.Original_Title, pd.Original_CreationDate,
    pd.Popularity_Status
HAVING 
    pd.UpVotePercentage IS NOT NULL AND pd.UpVotePercentage > 0
ORDER BY 
    pd.RankByViews
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
