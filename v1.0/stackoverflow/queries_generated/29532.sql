WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag, 
        COUNT(*)
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Only top 5 posts per tag
    GROUP BY 
        Tag
    ORDER BY 
        COUNT(*) DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TagEngagement AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(e.QuestionCount, 0)) AS EngagedUserCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        UserEngagement e ON e.QuestionCount > 0 
    WHERE 
        t.Count > 50 -- Popular tags
    GROUP BY 
        t.TagName
)
SELECT 
    t.TagName, 
    t.PostCount, 
    t.EngagedUserCount, 
    CASE 
        WHEN t.EngagedUserCount > 50 THEN 'Highly Engaged'
        WHEN t.EngagedUserCount > 20 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TagEngagement t
ORDER BY 
    t.PostCount DESC;
