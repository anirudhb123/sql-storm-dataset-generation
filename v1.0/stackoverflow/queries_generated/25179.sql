WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions
        AND p.CreationDate >= now() - interval '5 years' -- Posts from the last 5 years
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TotalPosts,
        SUM(COALESCE(pt.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(pt.ViewCount, 0)) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%' -- Assuming Tags storage in a text format with delimited values
    GROUP BY 
        t.TagName
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.Score,
    rp.ViewCount,
    ts.TagName,
    ts.TotalPosts,
    ts.TotalAnswers,
    ts.TotalViews,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.TagId = ts.TagName -- This assumes there's a way to join on Tags, else this would be adjusted
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.Rank <= 10 -- Only top 10 posts per year
ORDER BY 
    rp.CreationDate DESC;
