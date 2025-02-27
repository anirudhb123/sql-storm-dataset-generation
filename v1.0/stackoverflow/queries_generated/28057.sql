WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        PopularTags
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id
)
SELECT 
    upc.DisplayName,
    upc.TotalPosts,
    upc.TotalQuestions,
    upc.TotalAnswers,
    ub.TotalBadges,
    tt.TagName,
    tt.TagCount,
    pai.CommentCount,
    pai.VoteCount
FROM 
    UserPostCounts upc
JOIN 
    UserBadges ub ON upc.UserId = ub.UserId
JOIN 
    TopTags tt ON tt.TagRank <= 10 -- Top 10 tags
JOIN 
    PostInteractions pai ON pai.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = upc.UserId
    )
ORDER BY 
    upc.TotalPosts DESC, ub.TotalBadges DESC;
