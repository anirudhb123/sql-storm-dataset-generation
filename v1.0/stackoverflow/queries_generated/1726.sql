WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.Tags,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS tag,
        COUNT(*) AS tag_count
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        tag
    ORDER BY 
        tag_count DESC
    LIMIT 10
)
SELECT 
    up.DisplayName,
    up.CreationDate AS UserCreationDate,
    up.PostCount,
    up.Upvotes,
    up.Downvotes,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    pt.tag,
    pt.tag_count
FROM 
    UserActivity up
JOIN 
    RankedPosts p ON up.UserId = p.OwnerUserId
JOIN 
    PopularTags pt ON p.Tags LIKE '%' || pt.tag || '%'
WHERE 
    p.rn = 1
ORDER BY 
    up.Upvotes DESC, 
    p.Score DESC;
