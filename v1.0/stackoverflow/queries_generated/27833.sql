WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers,
        MAX(p.CreationDate) AS LastActivePostDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.PositivePostCount,
    ts.AverageScore,
    ts.ActiveUsers,
    ts.LastActivePostDate,
    p_hd.HistoryTypes,
    p_hd.LastEditedDate,
    p_hd.Editors,
    ua.DisplayName AS UserName,
    ua.CommentCount,
    ua.VoteCount,
    ua.BadgeCount,
    ua.TotalCommentScore
FROM 
    TagStatistics ts
JOIN 
    PostHistoryDetails p_hd ON ts.PostCount > 0
JOIN 
    UserActivity ua ON ua.CommentCount > 0
ORDER BY 
    ts.PostCount DESC, ua.TotalCommentScore DESC;
