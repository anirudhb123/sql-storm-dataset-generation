WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) pb ON u.Id = pb.UserId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP)
), UserAggregates AS (
    SELECT 
        OwnerUserId,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
)
SELECT 
    rp.OwnerDisplayName,
    u.Reputation,
    ua.TotalScore,
    ua.TotalViews,
    ua.TotalAnswers,
    ua.TotalComments,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.OwnerUserId = rp.OwnerUserId) AS AssociatedTags
FROM 
    RankedPosts rp
JOIN 
    UserAggregates ua ON rp.OwnerUserId = ua.OwnerUserId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    ua.TotalScore DESC, u.Reputation DESC;
