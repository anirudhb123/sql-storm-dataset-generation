WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),

TagStats AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors,
        AVG(p.ViewCount) AS AverageViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Posts p
    GROUP BY 
        TagName
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalComments,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    t.TagName,
    t.PostCount AS TagPostCount,
    t.UniqueAuthors AS TagUniqueAuthors,
    t.AverageViews AS TagAvgViews,
    t.TotalAnswers AS TagTotalAnswers
FROM 
    UserActivity u
LEFT JOIN 
    TagStats t ON u.PostCount > 0
ORDER BY 
    u.PostCount DESC, u.TotalComments DESC, t.AverageViews DESC;
