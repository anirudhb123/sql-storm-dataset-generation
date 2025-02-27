
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(DISTINCT Id) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.ViewCount,
    rp.AnswerCount,
    rp.BadgeCount,
    rp.CreationDate,
    GROUP_CONCAT(rt.Name SEPARATOR ', ') AS RelatedTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
LEFT JOIN 
    PostTypes rt ON rp.PostTypeId = rt.Id
WHERE 
    rp.TagRank <= 5 
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerName, rp.ViewCount, rp.AnswerCount, rp.BadgeCount, rp.CreationDate
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
