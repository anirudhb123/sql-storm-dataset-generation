
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            TRIM(REGEXP_SUBSTR(Tags, '[^>]+', 1, seq)) AS TagName
        FROM 
            Posts,
            TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq
        WHERE 
            PostTypeId = 1
            AND seq <= LEN(Tags) - LEN(REPLACE(Tags, '>', '')) + 1
    ) AS TagsTable
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    ur.DisplayName AS User,
    ur.Reputation,
    ur.Views,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    tt.TagName,
    tt.TagCount,
    rp.UserPostRank
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
JOIN 
    TopTags tt ON tt.TagName = ANY(ARRAY_FILTER(TO_VARIANT(REGEXP_SPLIT_TO_ARRAY(rp.Tags, '>')), x -> x IS NOT NULL))
WHERE 
    rp.UserPostRank <= 3 
ORDER BY 
    ur.Reputation DESC, rp.ViewCount DESC;
