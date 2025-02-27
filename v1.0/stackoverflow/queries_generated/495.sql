WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted' ELSE 'Not Accepted' END AS AnswerStatus,
        COALESCE(ph.HistoryCount, 0) AS EditCount,
        COALESCE(ph.LastActionDate, '1970-01-01'::timestamp) AS LastEditDate,
        ts.TotalViews AS TagTotalViews
    FROM 
        Posts p
    LEFT JOIN 
        PostHistories ph ON p.Id = ph.PostId
    LEFT JOIN 
        TagStatistics ts ON p.Tags LIKE '%' || ts.TagName || '%'
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerStatus,
    pd.EditCount,
    pd.LastEditDate,
    ud.TotalPosts,
    ud.TotalComments,
    ud.TotalBounty
FROM 
    UserActivity ud
JOIN 
    PostDetails pd ON ud.UserId = pd.OwnerUserId
WHERE 
    (ud.TotalPosts > 5 OR ud.TotalComments > 10)
    AND pd.ViewCount > 100
ORDER BY 
    ud.TotalBounty DESC,
    pd.ViewCount DESC
LIMIT 50;
