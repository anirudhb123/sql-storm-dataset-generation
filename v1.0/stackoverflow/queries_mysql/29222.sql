
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title AS PostTitle, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
RankedPosts AS (
    SELECT 
        tp.PostId,
        tp.PostTitle,
        tp.Tag,
        ROW_NUMBER() OVER (PARTITION BY tp.Tag ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        TaggedPosts tp
    JOIN 
        Posts p ON p.Id = tp.PostId
    WHERE 
        p.ViewCount > 1000  
),
RecentEdits AS (
    SELECT 
        ph.PostId AS EditedPostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Tag,
    rp.PostTitle,
    re.LastEditDate,
    re.EditCount,
    ur.DisplayName AS UserName,
    ur.Reputation AS UserReputation,
    ur.BadgeCount AS UserBadgeCount
FROM 
    RankedPosts rp
JOIN 
    RecentEdits re ON rp.PostId = re.EditedPostId
JOIN 
    Posts p ON p.Id = rp.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
JOIN 
    UserReputation ur ON ur.UserId = u.Id
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    rp.Tag, re.LastEditDate DESC;
