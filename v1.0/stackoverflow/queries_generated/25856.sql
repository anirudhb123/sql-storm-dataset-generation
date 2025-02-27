WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, '<>')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Consider only questions
    GROUP BY 
        p.Id
),
HighScoringQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        Score,
        ViewCount,
        Tags,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '30 days' -- Users created in the last 30 days
    GROUP BY 
        u.Id
),
UserPostStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        SUM(rq.ViewCount) AS TotalViews,
        SUM(rq.CommentCount) AS TotalComments,
        COUNT(rq.PostId) AS TotalQuestions
    FROM 
        RecentUsers u
    LEFT JOIN 
        HighScoringQuestions rq ON rq.Tags ILIKE '%' || u.DisplayName || '%'
    GROUP BY 
        u.UserId, u.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.TotalQuestions,
    ups.TotalViews,
    ups.TotalComments,
    RANK() OVER (ORDER BY ups.TotalViews DESC) AS RankByViews
FROM 
    UserPostStats ups
WHERE 
    ups.TotalQuestions > 0
ORDER BY 
    RankByViews;
