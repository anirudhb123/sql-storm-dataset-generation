WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.TotalViews,
    us.DisplayName,
    us.Reputation,
    us.QuestionsAsked,
    us.AnswersGiven,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.VoteCount,
    pa.LastEdited
FROM 
    TagStatistics ts
JOIN 
    UserStatistics us ON us.Reputation > 1000 -- arbitrary reputation threshold
JOIN 
    PostActivity pa ON pa.CommentCount > 5 -- arbitrary comment count threshold
ORDER BY 
    ts.TotalViews DESC, us.Reputation DESC, pa.VoteCount DESC
LIMIT 50;
