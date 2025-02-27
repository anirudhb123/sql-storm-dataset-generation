WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),

PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 -- Only tags with more than 5 occurrences
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        MAX(u.CreationDate) AS AccountAge
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalViews DESC
),

ActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Score,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    WHERE 
        rp.ViewCount > 100 -- Only active posts
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalViews,
    ua.TotalScore,
    AVG(ua.AccountAge) AS AvgAccountAge,
    pt.Title AS PopularPostTitle,
    pt.ViewCount AS PopularPostViews,
    pt.AnswerCount AS PopularPostAnswers,
    pt.CommentCount AS PopularPostComments,
    pt.Score AS PopularPostScore,
    t.TagName AS PopularTag
FROM 
    UserActivity ua
JOIN 
    ActivePosts pt ON ua.TotalPosts > 0
JOIN 
    PopularTags t ON pt.Tags @> ARRAY[t.TagName] -- Filter on popular tags
GROUP BY 
    ua.UserId, ua.DisplayName, pt.Title, pt.ViewCount, pt.AnswerCount, pt.CommentCount, pt.Score, t.TagName
ORDER BY 
    ua.TotalViews DESC, PopularPostScore DESC
LIMIT 10;
