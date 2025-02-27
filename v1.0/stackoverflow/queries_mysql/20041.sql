
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS TagName 
         FROM Posts 
         CROSS JOIN (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t, 
         (SELECT @row := 0) r) n 
         WHERE Tags IS NOT NULL) AS t
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.PostHistoryTypeId) AS HistoryTypeCount,
        MAX(ph.CreationDate) AS LastActivity
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.QuestionCount,
    ups.AnswerCount,
    COALESCE(bs.GoldCount, 0) AS GoldBadges,
    COALESCE(bs.SilverCount, 0) AS SilverBadges,
    COALESCE(bs.BronzeCount, 0) AS BronzeBadges,
    GROUP_CONCAT(pt.TagName) AS PopularTags,
    phc.HistoryTypeCount,
    phc.LastActivity
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgeSummary bs ON ups.UserId = bs.UserId
LEFT JOIN 
    PopularTags pt ON true  
LEFT JOIN 
    PostHistoryCounts phc ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = phc.PostId LIMIT 1) 
GROUP BY 
    ups.UserId, ups.DisplayName, ups.PostCount, ups.TotalScore, ups.QuestionCount, ups.AnswerCount, 
    bs.GoldCount, bs.SilverCount, bs.BronzeCount, phc.HistoryTypeCount, phc.LastActivity
HAVING 
    ups.PostCount > 5 AND 
    (COALESCE(bs.GoldCount, 0) > 0 OR COALESCE(bs.SilverCount, 0) > 0 OR COALESCE(bs.BronzeCount, 0) > 0) 
ORDER BY 
    ups.TotalScore DESC;
