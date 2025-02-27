
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @current_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation
),

MaxUserReputation AS (
    SELECT 
        UserId,
        MAX(Reputation) AS MaxReputation
    FROM 
        UserReputation
    GROUP BY 
        UserId
),

TopTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
    ORDER BY 
        PostCount DESC
    LIMIT 5
)

SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tt.TagName
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    MaxUserReputation mur ON up.Id = mur.UserId
JOIN 
    TopTags tt ON tt.PostCount > 0
WHERE 
    rp.PostRank = 1
ORDER BY 
    mur.MaxReputation DESC, rp.Score DESC;
