WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RankedTags AS (
    SELECT 
        ts.*,
        RANK() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS RankByScore,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPosts
    FROM 
        TagStats ts
)
SELECT 
    rt.TagName,
    rt.PostCount,
    rt.TotalViews,
    rt.TotalScore,
    rt.CommentCount,
    rt.GoldBadges,
    rt.SilverBadges,
    rt.BronzeBadges,
    rt.RankByScore,
    rt.RankByPosts
FROM 
    RankedTags rt
WHERE 
    rt.RankByScore <= 10 OR rt.RankByPosts <= 10
ORDER BY 
    rt.RankByScore, rt.RankByPosts;
