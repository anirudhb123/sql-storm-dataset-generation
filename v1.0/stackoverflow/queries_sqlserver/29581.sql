
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
            value AS TagName
        FROM 
            Posts
        CROSS APPLY STRING_SPLIT(Tags, '>') AS TagsTable
        WHERE 
            PostTypeId = 1
    ) AS TagsTable
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    UserReputation ur ON rp.PostId = ur.UserId
JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '>'))
WHERE 
    rp.UserPostRank <= 3 
ORDER BY 
    ur.Reputation DESC, rp.ViewCount DESC;
