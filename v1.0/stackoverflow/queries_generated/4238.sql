WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
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
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        ur.DisplayName,
        ur.Reputation,
        ur.Location,
        ur.BadgeCount,
        ps.PostCount,
        ps.TotalViews,
        ps.AverageScore,
        ps.QuestionCount,
        ps.AnswerCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        PostStats ps ON ur.UserId = ps.OwnerUserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COALESCE(up.Location, 'Unknown') AS Location,
    COALESCE(up.BadgeCount, 0) AS BadgeCount,
    COALESCE(up.PostCount, 0) AS PostCount,
    COALESCE(up.TotalViews, 0) AS TotalViews,
    COALESCE(up.AverageScore, 0) AS AverageScore,
    COALESCE(up.QuestionCount, 0) AS QuestionCount,
    COALESCE(up.AnswerCount, 0) AS AnswerCount
FROM 
    UserPerformance up
ORDER BY 
    up.Reputation DESC,
    up.PostCount DESC
LIMIT 50;

WITH TrendingPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.Id) DESC) AS TrendingRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes
FROM 
    TrendingPosts tp
WHERE 
    tp.TrendingRank <= 10
ORDER BY 
    tp.CommentCount DESC, tp.UpVotes - tp.DownVotes DESC;

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
ORDER BY 
    AvgViews DESC;
