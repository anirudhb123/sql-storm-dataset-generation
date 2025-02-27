WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUserPosts AS (
    SELECT 
        p.OwnerUserId AS PostOwnerId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE 
                WHEN p.PostTypeId = 1 THEN 1 
                ELSE 0 
            END) AS Questions,
        SUM(CASE 
                WHEN p.PostTypeId = 2 THEN 1 
                ELSE 0 
            END) AS Answers
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '365 days')
    GROUP BY 
        p.OwnerUserId
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')::int[])
    GROUP BY 
        p.Id
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(ap.TotalPosts,0) AS PostsInLastYear,
    COALESCE(ap.Questions,0) AS TotalQuestions,
    COALESCE(ap.Answers,0) AS TotalAnswers,
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Tags
FROM 
    UserBadgeStats ub
LEFT JOIN 
    ActiveUserPosts ap ON ub.UserId = ap.PostOwnerId
LEFT JOIN 
    PostDetail pd ON pd.ViewCount > 100 AND pd.Score > 0
WHERE 
    ub.TotalBadges > 0
ORDER BY 
    ub.TotalBadges DESC, 
    ap.TotalPosts DESC NULLS LAST,
    pd.Score DESC, 
    pd.ViewCount DESC;

