WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClasses,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    GROUP BY 
        u.Id
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId 
    WHERE 
        p.PostTypeId = 1 AND 
        p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Tags, p.ViewCount, p.AnswerCount, p.CommentCount
),
FlattenedTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, ',')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
PostSummary AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.ViewCount,
        ap.AnswerCount,
        ap.CommentCount,
        STRING_AGG(ft.Tag, ', ') AS Tags
    FROM 
        ActivePosts ap
    LEFT JOIN 
        FlattenedTags ft ON ap.PostId = ft.PostId
    GROUP BY 
        ap.PostId, ap.Title, ap.ViewCount, ap.AnswerCount, ap.CommentCount
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBounties,
    us.TotalBadgeClasses,
    us.PostHistoryCount,
    rp.PostId AS HighestScoredPostId,
    rp.Title AS HighestScoredPostTitle,
    ps.ViewCount AS HighestScoredPostViewCount,
    ps.AnswerCount AS HighestScoredPostAnswerCount,
    ps.CommentCount AS HighestScoredPostCommentCount,
    ps.Tags AS HighestScoredPostTags
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    PostSummary ps ON rp.PostId = ps.PostId
WHERE 
    us.TotalBounties > 0 OR us.TotalBadgeClasses > 0
ORDER BY 
    us.DisplayName ASC
OPTION (RECOMPILE);
