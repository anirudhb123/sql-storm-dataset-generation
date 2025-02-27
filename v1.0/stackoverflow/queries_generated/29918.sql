WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        AVG(DATEDIFF(day, p.CreationDate, GETDATE())) AS AvgPostAgeDays,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000  -- Only include users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')   -- Assume tags are wrapped in <>
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10  -- Only consider tags with multiple associated posts
),

PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        DATEDIFF(hour, p.CreationDate, GETDATE()) AS PostAgeHours,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgPostAgeDays,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pt.TagName,
    pt.TagPostCount,
    pa.PostId,
    pa.Title,
    pa.PostAgeHours,
    pa.ViewCount,
    pa.Score,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount
FROM 
    UserStatistics us
CROSS JOIN 
    PopularTags pt
JOIN 
    PostActivity pa ON us.UserId = pa.OwnerUserId
ORDER BY 
    us.Reputation DESC, 
    pt.TagPostCount DESC, 
    pa.ViewCount DESC;
