WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount, 
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 50
),
UserPostAssociations AS (
    SELECT 
        ru.UserId,
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreatedDate,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments' 
            ELSE 'No Comments' 
        END AS CommentStatus,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RecentUsers ru
    LEFT JOIN 
        RankedPosts rp ON ru.UserId = rp.OwnerUserId 
    WHERE 
        rp.Rank = 1 AND rp.CommentCount IS NOT NULL
)
SELECT 
    u.DisplayName,
    COUNT(up.PostId) AS TotalPosts,
    SUM(CASE WHEN up.UpvoteCount > up.DownvoteCount THEN 1 ELSE 0 END) AS PositiveEngagements,
    STRING_AGG(DISTINCT up.Title, '; ') AS PostTitles,
    NULLIF(SUM(up.ViewCount), 0) AS TotalViews,
    MAX(COALESCE(up.CreatedDate, '1900-01-01'::timestamp)) AS LastPostDate
FROM 
    UserPostAssociations up
JOIN 
    Users u ON up.UserId = u.Id
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(up.PostId) > 3 AND MAX(up.CreatedDate) > NOW() - INTERVAL '6 months'
ORDER BY 
    TotalPosts DESC, TotalViews DESC;

-- An additional section that utilizes an outer join to get posts with potential links to other posts
SELECT 
    p.Title AS SourcePostTitle,
    COALESCE(lp.RelatedPostTitle, 'No Related Post') AS RelatedPostTitle,
    CASE 
        WHEN p.ViewCount > 100 THEN 'Popular Post' 
        ELSE 'Less Popular Post' 
    END AS PopularityStatus
FROM 
    Posts p
LEFT JOIN 
    (SELECT ll.PostId, pp.Title AS RelatedPostTitle 
     FROM PostLinks ll 
     JOIN Posts pp ON ll.RelatedPostId = pp.Id) lp ON p.Id = lp.PostId
WHERE 
    p.ViewCount BETWEEN 10 AND 1000
ORDER BY 
    p.CreationDate DESC;
