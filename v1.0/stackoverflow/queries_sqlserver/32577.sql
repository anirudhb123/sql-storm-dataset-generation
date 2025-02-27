
WITH PostViews AS (
    SELECT 
        p.Id, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    OUTER APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(p.Tags, '>') 
    ) AS t 
    GROUP BY u.Id, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(th.TagPostCount, 0) AS TagPostCount,
        vp.VoteCount,
        vp.Upvotes,
        vp.Downvotes
    FROM Posts p
    LEFT JOIN (
        SELECT 
            t.Id,
            COUNT(DISTINCT p.Id) AS TagPostCount
        FROM Tags t
        LEFT JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
        GROUP BY t.Id
    ) AS th ON th.Id = p.Id
    LEFT JOIN PostViews vp ON vp.Id = p.Id
    WHERE p.CreationDate >= DATEADD(month, -6, '2024-10-01 12:34:56')
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.CommentCount,
    u.TotalViews,
    p.Title,
    p.TagPostCount,
    p.VoteCount,
    p.Upvotes,
    p.Downvotes
FROM UserEngagement u
CROSS JOIN TaggedPosts p
ORDER BY 
    u.TotalViews DESC,
    p.TagPostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
