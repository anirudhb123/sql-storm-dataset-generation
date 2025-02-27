WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pp.Count AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags pp ON pp.TagName = ANY(string_to_array(p.Tags, '>'))
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days' 
        AND p.PostTypeId = 1 -- Only questions
        AND p.ViewCount > 100 -- Only popular questions
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.TagCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ans.AnswerCount, 0) AS AnswerCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON rp.PostId = c.PostId
    LEFT JOIN 
        (SELECT ParentId AS PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) ans ON rp.PostId = ans.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.TagCount
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.Body,
    pa.OwnerDisplayName,
    pa.CreationDate,
    pa.TagCount,
    pa.CommentCount,
    pa.AnswerCount,
    pa.BadgeCount,
    CONCAT('This question has ', pa.AnswerCount, ' answers and ', pa.CommentCount, ' comments which makes it very engaging.') AS EngagementMessage
FROM 
    PostAnalytics pa
WHERE 
    pa.BadgeCount > 0 -- Only posts from users with badges
ORDER BY 
    pa.CreationDate DESC, pa.AnswerCount DESC;
