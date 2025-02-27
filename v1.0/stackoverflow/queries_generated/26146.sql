WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT tag.TagName) AS TagCount
    FROM 
        Posts p 
    JOIN 
        Tags t ON t.Id IN (
            SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
        )
    GROUP BY 
        p.Id
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostActivityStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        COALESCE(p.Score, 0) AS Score
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId IN (4, 5) -- Edit Title, Edit Body
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    u.GoldCount,
    u.SilverCount,
    u.BronzeCount,
    p.PostId,
    p.AnswerCount,
    p.CommentCount,
    p.ViewCount,
    p.EditCount,
    p.Score,
    pc.TagCount
FROM 
    UserBadges u
JOIN 
    PostActivityStats p ON p.PostId IN (
        SELECT Id FROM Posts WHERE OwnerUserId = u.UserId
    )
JOIN 
    PostTagCounts pc ON pc.PostId = p.PostId
ORDER BY 
    u.Reputation DESC, p.Score DESC;
