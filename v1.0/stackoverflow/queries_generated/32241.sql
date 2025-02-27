WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0 -- Only positive scoring questions
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
        AND Tags IS NOT NULL
),
TagCount AS (
    SELECT 
        Tag, COUNT(*) AS TagUsage
    FROM 
        PopularTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) >= 10 -- Tags used in at least 10 questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
UserMetrics AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.QuestionCount,
        ur.BadgeCount,
        CASE
            WHEN ur.Reputation > 1000 THEN 'Expert'
            WHEN ur.Reputation > 100 THEN 'Intermediate'
            ELSE 'Beginner'
        END AS UserLevel
    FROM 
        UserReputation ur
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    um.Reputation,
    um.UserLevel,
    tc.Tag,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    UserMetrics um ON rp.OwnerDisplayName = um.UserId
LEFT JOIN 
    Comments c ON c.PostId = rp.PostId
LEFT JOIN 
    TagCount tc ON tc.Tag = ANY (SELECT unnest(string_to_array(rp.Tags, '><')))
WHERE 
    rp.PostRank = 1 -- Get only the latest post per user
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.OwnerDisplayName, 
    um.Reputation, um.UserLevel, tc.Tag
ORDER BY 
    rp.Score DESC, um.Reputation DESC
LIMIT 50; -- Limit for performance
