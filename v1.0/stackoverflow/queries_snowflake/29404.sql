
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT TRIM(value) AS TagName 
                  FROM TABLE(TRANSFORM_TO_ARRAY(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) 
                  WHERE value IS NOT NULL) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.CreationDate >= TIMESTAMPADD(year, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
ActiveUserPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.CommentCount,
        pm.Score,
        pm.Tags
    FROM 
        UserActivity ua
    JOIN 
        PostMetrics pm ON pm.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = ua.UserId
        )
)
SELECT 
    a.DisplayName,
    COUNT(a.PostId) AS NumberOfPosts,
    SUM(a.ViewCount) AS TotalViews,
    AVG(a.Score) AS AvgScore,
    LISTAGG(a.Tags, ', ') WITHIN GROUP (ORDER BY a.Tags) AS AssociatedTags
FROM 
    ActiveUserPosts a
GROUP BY 
    a.DisplayName
ORDER BY 
    NumberOfPosts DESC
LIMIT 10;
