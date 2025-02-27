WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ARRAY_AGG(DISTINCT TRIM(BOTH '<>' FROM UNNEST(string_to_array(p.Tags, '>')))) AS TagsArray,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        Posts p
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount, p.FavoriteCount
),
BadgeUserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    b.BadgeCount,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges,
    UPS.TotalPosts,
    UPS.QuestionsCount,
    UPS.AnswersCount,
    UPS.TotalScore,
    p.TagsArray,
    p.PostCategory
FROM 
    PostTagStats p
JOIN 
    Users u ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
JOIN 
    BadgeUserStats b ON u.Id = b.UserId
JOIN 
    UserPostStats UPS ON u.Id = UPS.OwnerUserId
WHERE 
    p.ViewCount > 100 AND
    p.Score > 0
ORDER BY 
    p.ViewCount DESC, p.Score DESC
LIMIT 100;
