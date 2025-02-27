
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        (SELECT DISTINCT tag FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
               SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) AS numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),

RecentActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.Tags,
        rp.VoteRank,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS RecentRank
    FROM
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE
        p.LastActivityDate >= CURRENT_DATE - INTERVAL 30 DAY  
)

SELECT
    u.DisplayName,
    ra.PostId,
    ra.Title,
    ra.Body,
    ra.CreationDate,
    ra.CommentCount,
    ra.Tags,
    ra.VoteRank
FROM 
    RecentActivePosts ra
JOIN 
    Users u ON ra.OwnerUserId = u.Id
WHERE
    ra.RecentRank <= 10  
ORDER BY
    ra.CommentCount DESC, ra.VoteRank ASC;
