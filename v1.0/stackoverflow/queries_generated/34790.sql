WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
LatestPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        COALESCE(ah.AnsweredCount, 0) AS AnsweredCount
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnsweredCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivityWithRanks AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS Rank
    FROM 
        RecursiveUserActivity u
    JOIN 
        LatestPosts p ON u.PostCount > 0
    WHERE 
        u.PostCount > 0
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    lp.Title,
    lp.ViewCount,
    lp.Score,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(DISTINCT c.Id) AS TotalComments,
    CASE 
        WHEN ua.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    UserActivityWithRanks ua
LEFT JOIN 
    LatestPosts lp ON ua.PostId = lp.PostId
LEFT JOIN 
    Votes v ON lp.PostId = v.PostId 
        AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
LEFT JOIN 
    Comments c ON lp.PostId = c.PostId
GROUP BY 
    ua.DisplayName, ua.Reputation, lp.Title, lp.ViewCount, lp.Score, ua.Rank
ORDER BY 
    TotalBounty DESC, ua.Reputation DESC
LIMIT 50;
