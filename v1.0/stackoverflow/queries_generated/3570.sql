WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as Rank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) as CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
),
TopQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostTypeId = 1 AND rp.Rank <= 10
),
UserReputationBoost AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation + COALESCE(SUM(b.Class), 0) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    u.DisplayName,
    u.Location,
    ur.TotalReputation,
    CASE 
        WHEN tq.CommentCount > 10 THEN 'High Engagement'
        WHEN tq.CommentCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopQuestions tq
JOIN 
    Users u ON u.Id = tq.OwnerUserId
JOIN 
    UserReputationBoost ur ON ur.UserId = u.Id
LEFT JOIN 
    PostLinks pl ON pl.PostId = tq.Id
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = tq.Id 
        AND v.VoteTypeId = 2
    )
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
