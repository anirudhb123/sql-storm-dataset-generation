WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        p.Score,
        ARRAY_AGG(t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.PostTypeId = 1  -- Including only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
), UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswersPerPost
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
)

SELECT 
    u.UserId,
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalViews,
    ups.TotalScore,
    ups.AvgAnswersPerPost,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Tags,
    tt.TagName AS TopTag,
    tt.TagUsageCount
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
JOIN 
    RankedPosts rp ON rp.ViewRank <= 5  -- Top 5 viewed posts per user
LEFT JOIN 
    TopTags tt ON TRUE  -- Join with TopTags for tag usage
ORDER BY 
    u.TotalViews DESC, rp.ViewCount DESC;
