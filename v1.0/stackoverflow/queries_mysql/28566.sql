
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 5 
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1 
    WHERE 
        p.PostTypeId = 1 
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(pt.PostId) AS TagCount
    FROM 
        PostTags pt
    GROUP BY 
        Tag
    HAVING 
        COUNT(pt.PostId) > 10 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    pt.Tag,
    tp.TagCount
FROM 
    TopUsers u
JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
JOIN 
    PostTags pt ON rp.PostId = pt.PostId
JOIN 
    TagPopularity tp ON pt.Tag = tp.Tag
WHERE 
    rp.UserPostRank = 1 
ORDER BY 
    u.Reputation DESC, 
    tp.TagCount DESC;
