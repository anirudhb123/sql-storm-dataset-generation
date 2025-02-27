
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_user := p.OwnerUserId,
        p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1  
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Tags,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5  
),
PopularTags AS (
    SELECT 
        t.TagName,  
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName  
        FROM 
            Posts 
        JOIN 
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
             SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
        WHERE 
            PostTypeId = 1
    ) AS t
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10  
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.BadgeCount,
    tq.BadgeNames,
    pt.TagName,
    pt.TagCount
FROM 
    TopQuestions tq
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, REPLACE(REPLACE(tq.Tags, '><', ','), '>', ''))  
ORDER BY 
    tq.Score DESC, tq.CreationDate DESC;
