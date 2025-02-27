WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        CASE 
            WHEN p.AnnualViewCount IS NULL THEN 0 
            ELSE p.AnnualViewCount 
        END AS AnnualViews
    FROM 
        Posts p
    JOIN (
        SELECT 
            PostId, 
            SUM(ViewCount) AS AnnualViewCount
        FROM 
            Posts
        WHERE 
            CreationDate >= DATEADD(YEAR, -1, GETDATE())
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
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
), 
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_SPLIT(p.Tags, ',') t ON t.value = t.TagName
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    ue.UserId,
    ue.DisplayName,
    ue.CommentCount,
    ue.UpvoteCount,
    ue.DownvoteCount,
    pe.TotalUpvotes,
    pe.TotalDownvotes,
    pe.TotalComments,
    pe.AssociatedTags
FROM 
    PopularPosts pp
LEFT JOIN 
    Users u ON pp.PostOwnerId = u.Id
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    PostEngagement pe ON pp.PostId = pe.PostId
WHERE 
    pp.Score > 10 AND 
    (pp.ViewCount > 1000 OR pp.ViewCount IS NULL) 
ORDER BY 
    pp.ViewCount DESC
OPTION (RECOMPILE);
