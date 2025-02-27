WITH RecursivePostStats AS (
    SELECT
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(pa.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts pa ON p.Id = pa.AcceptedAnswerId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, pa.AcceptedAnswerId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.CreationDate::date, ' - ', pht.Name), ' | ') AS HistoryInfo,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TagPopularity AS (
    SELECT 
        t.Id,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViewCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.VoteCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ptd.HistoryInfo,
    ptd.CloseCount,
    ptd.DeleteCount,
    tp.TagName,
    tp.TotalViewCount AS TagTotalViews,
    CASE 
        WHEN tp.Rank <= 5 THEN 'Top 5 Tag'
        WHEN tp.Rank BETWEEN 6 AND 15 THEN 'Top 15 Tag'
        ELSE 'Other Tag' 
    END AS TagCategory
FROM 
    RecursivePostStats ps
JOIN 
    PostHistoryDetails ptd ON ps.Id = ptd.PostId
LEFT JOIN 
    TagPopularity tp ON tp.PostCount > 0
WHERE 
    (ps.ViewCount > 100 OR ps.VoteCount > 10) 
    AND (ps.AcceptedAnswerId IS NULL OR ps.AcceptedAnswerId <> -1)
ORDER BY 
    ps.ViewCount DESC, 
    ps.Title ASC
LIMIT 100;
