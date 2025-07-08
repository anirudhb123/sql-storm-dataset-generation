
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.Reputation
),

TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(*) AS QuestionCount
    FROM (
        SELECT 
            FLATTEN(INPUT => STRING_SPLIT(Tags, '>')) AS TagName
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
    ) AS t
    GROUP BY 
        t.TagName
),

UserTags AS (
    SELECT 
        u.Id AS UserId,
        LISTAGG(DISTINCT t.TagName, ', ') AS UserTags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        LATERAL FLATTEN(INPUT => STRING_SPLIT(p.Tags, '>')) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ur.Reputation,
    ur.TotalQuestions,
    ur.PositiveScoredQuestions,
    ut.UserTags,
    ts.QuestionCount AS TagQuestionCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
JOIN 
    UserTags ut ON rp.OwnerUserId = ut.UserId
JOIN 
    TagStatistics ts ON ts.TagName IN (SELECT TRIM(value) FROM TABLE(FLATTEN(INPUT => STRING_SPLIT(rp.Tags, '>'))))
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC;
