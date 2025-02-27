WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        unnest(string_to_array(Tags, '><'))
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 10 -- Only include users with more than 10 posts
),
PostCommentStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    ps.CommentCount,
    ps.LastCommentDate,
    pt.TagName AS PopularTag,
    ups.TotalScore AS UserTotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    PostCommentStats ps ON rp.PostId = ps.PostId
CROSS JOIN 
    PopularTags pt
LEFT JOIN 
    UserPostStats ups ON rp.OwnerUserId = ups.UserId
WHERE 
    rp.PostRank = 1 -- Get only the latest post per user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

