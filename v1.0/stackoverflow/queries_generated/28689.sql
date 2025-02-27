WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
        AND p.CreationDate >= '2023-01-01' -- Limit to this year
),
PostTags AS (
    SELECT 
        rp.PostId,
        unnest(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')) AS Tag
    FROM 
        RankedPosts rp
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.QuestionCount,
    tt.Tag AS MostUsedTag,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score
FROM 
    UserReputation ur
JOIN 
    RankedPosts tp ON ur.UserId = tp.OwnerUserId
JOIN 
    PostTags pt ON tp.PostId = pt.PostId
JOIN 
    TopTags tt ON pt.Tag = tt.Tag
WHERE 
    tp.Rank = 1 -- Only take the latest question for each user
ORDER BY 
    ur.Reputation DESC, 
    tp.ViewCount DESC;
