
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Title IS NOT NULL
),

TagStatistics AS (
    SELECT 
        TRIM(BOTH '<>' FROM value) AS TagName,
        COUNT(*) AS TagCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Posts p,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><'))) AS t
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TRIM(BOTH '<>' FROM value)
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        ARRAY_AGG(DISTINCT b.Name) AS UserBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    ts.TagCount,
    ts.AcceptedAnswerCount,
    ub.BadgeCount,
    ub.UserBadges
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON POSITION(ts.TagName IN rp.Tags) > 0 
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.TagRank <= 10 
ORDER BY 
    rp.Tags, rp.CreationDate DESC;
