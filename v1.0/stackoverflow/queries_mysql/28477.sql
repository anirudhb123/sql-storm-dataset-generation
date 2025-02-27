
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers
        JOIN 
            Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON TRUE
    WHERE
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        tags.TagName,
        COUNT(*) AS PopularityCount
    FROM 
        RankedPosts r
    CROSS JOIN 
        (SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.Tags, '><', numbers.n), '><', -1)) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers
        JOIN 
            RankedPosts r ON CHAR_LENGTH(r.Tags) - CHAR_LENGTH(REPLACE(r.Tags, '><', '')) >= numbers.n - 1) tags
    GROUP BY 
        tags.TagName
    ORDER BY 
        PopularityCount DESC
    LIMIT 10
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CommentCount,
    rp.AnswerCount,
    pt.TagName AS PopularTag,
    ur.UserId,
    ur.DisplayName AS UserDisplayName,
    ur.Reputation,
    ur.QuestionCount,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId = (
        SELECT 
            p.Id
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId IS NOT NULL 
        ORDER BY 
            p.CreationDate DESC 
        LIMIT 1
    )
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Tags) > 0
WHERE 
    rp.RankScore <= 50  
ORDER BY 
    rp.RankScore
LIMIT 100;
