WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
        AVG(CASE WHEN p.PostTypeId = 2 THEN p.Score END) AS AvgAnswerScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
HighlightedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 10
    ORDER BY 
        p.CreationDate DESC
    LIMIT 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))) , ', ') AS TagList
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        p.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.AvgQuestionScore,
    ups.AvgAnswerScore,
    hp.PostId,
    hp.Title,
    hp.Body,
    hp.CreationDate,
    hp.ViewCount,
    hp.Score,
    pc.CommentCount,
    pt.TagList
FROM 
    UserPostStats ups
JOIN 
    HighlightedPosts hp ON ups.UserId = hp.OwnerDisplayName
JOIN 
    PostComments pc ON hp.PostId = pc.PostId
JOIN 
    PostTags pt ON hp.PostId = pt.PostId
ORDER BY 
    ups.TotalPosts DESC, hp.ViewCount DESC;
