WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Tags
), PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(TRIM(BOTH '<>' FROM p.Tags), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        UNNEST(STRING_TO_ARRAY(TRIM(BOTH '<>' FROM p.Tags), '><'))
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000 -- Consider users with high reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Tags,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.TagCount,
    ur.DisplayName AS TopContributor,
    ur.Reputation AS ContributorReputation
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
JOIN 
    UserReputation ur ON rp.AnswerCount > 0 -- Join with users who have contributed answers
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.Score DESC, 
    pt.TagCount DESC, 
    ur.Reputation DESC
LIMIT 50;
