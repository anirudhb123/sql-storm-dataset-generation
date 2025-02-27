
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ',') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS t(TagName)
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
    CROSS APPLY 
        STRING_SPLIT(r.Tags, ',') AS tags(TagName)
    GROUP BY 
        tags.TagName
    ORDER BY 
        PopularityCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        SELECT TOP 1 
            p.Id
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId IS NOT NULL 
        ORDER BY 
            p.CreationDate DESC 
    )
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, ','))
WHERE 
    rp.RankScore <= 50  
ORDER BY 
    rp.RankScore
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;