WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (8, 9) THEN v.BountyAmount ELSE 0 END) AS TotalBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgePoints,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(ps.ViewCount) AS TotalPostViews,
        SUM(ps.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id
),
ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Anonymous') AS AuthorName,
        COALESCE(ps.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(ps.DownvoteCount, 0) AS DownvoteCount,
        COALESCE(ps.TotalBountyAmount, 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    ap.Id,
    ap.Title,
    ap.CreationDate,
    ap.Score,
    ap.ViewCount,
    ap.AnswerCount,
    ap.CommentCount,
    ap.AuthorName,
    ur.TotalBadgePoints AS AuthorBadgePoints,
    ur.TotalPosts AS AuthorTotalPosts,
    ur.TotalPostViews AS AuthorTotalViews,
    ur.TotalAnswers AS AuthorTotalAnswers,
    ap.UpvoteCount,
    ap.DownvoteCount,
    ap.TotalBounty
FROM 
    ActivePosts ap
JOIN 
    UserReputation ur ON ap.OwnerUserId = ur.UserId
ORDER BY 
    ap.ViewCount DESC,
    ap.Score DESC
LIMIT 50;
