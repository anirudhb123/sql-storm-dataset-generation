WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        IsModeratorOnly,
        IsRequired,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsRequired = 1
    
    UNION ALL
    
    SELECT
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        t.IsModeratorOnly,
        t.IsRequired,
        rt.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTags rt ON t.ExcerptPostId = rt.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- Bounty close
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS VersionRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounty,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)) AS TotalLinks,
    rt.TagName,
    RP.PostId,
    RP.CreationDate,
    RP.Comment,
    RP.Title
FROM 
    UserActivity ua
LEFT JOIN 
    RecursiveTags rt ON rt.IsRequired = 1
LEFT JOIN 
    RecentPostHistory RP ON RP.VersionRank = 1
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    ua.TotalBounty DESC, ua.TotalPosts DESC, rt.TagName ASC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
