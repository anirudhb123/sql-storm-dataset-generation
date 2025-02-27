WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
ViewsAndScores AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(l.LinkCount, 0) AS LinkCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON rp.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS LinkCount 
        FROM 
            PostLinks 
        GROUP BY 
            PostId
    ) l ON rp.Id = l.PostId
)
SELECT 
    vas.Title,
    vas.ViewCount,
    vas.Score,
    vas.AnswerCount,
    vas.LinkCount,
    CASE 
        WHEN vas.RankByViews <= 5 THEN 'Top Viewed'
        WHEN vas.RankByScore <= 5 THEN 'Top Scored'
        ELSE 'Others'
    END AS PostCategory,
    u.DisplayName,
    u.Reputation,
    u.Location
FROM 
    ViewsAndScores vas
JOIN 
    Users u ON vas.OwnerUserId = u.Id
WHERE 
    (vas.AnswerCount > 0 OR vas.LinkCount > 0)
ORDER BY 
    vas.ViewCount DESC, 
    vas.Score DESC
LIMIT 100;

