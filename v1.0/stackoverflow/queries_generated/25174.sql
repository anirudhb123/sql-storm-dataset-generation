WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(bg.Class, 0) AS BadgeClass,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges bg ON p.OwnerUserId = bg.UserId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, bg.Class
),
TopPostedUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    ranked.Title,
    ranked.Tags,
    ranked.CreationDate,
    ranked.Score,
    ranked.ViewCount,
    tp.TotalPosts,
    tp.TotalAnswers,
    tp.TotalComments,
    CASE 
        WHEN ranked.BadgeClass = 1 THEN 'Gold Badge'
        WHEN ranked.BadgeClass = 2 THEN 'Silver Badge'
        WHEN ranked.BadgeClass = 3 THEN 'Bronze Badge'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    RankedPosts ranked
JOIN 
    Users u ON ranked.OwnerUserId = u.Id
JOIN 
    TopPostedUsers tp ON u.Id = tp.OwnerUserId
WHERE 
    ranked.RecentPostRank <= 5 -- Limit to top 5 recent posts per user
ORDER BY 
    ranked.Score DESC, ranked.ViewCount DESC;
