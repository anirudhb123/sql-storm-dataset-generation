
WITH RECURSIVE UserBadges AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        1 AS Level
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    UNION ALL
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        b.Class,
        b.Date,
        ub.Level + 1
    FROM 
        Badges b
    INNER JOIN 
        UserBadges ub ON b.UserId = ub.UserId
    WHERE 
        b.Class IN (2, 3) AND ub.Level < 5  
),
PostTagCTE AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) TagName
         FROM (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL
               SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    GROUP BY 
        p.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
),
BenchmarkingStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        pt.TagCount,
        pt.UpVoteCount,
        pt.DownVoteCount,
        ub.BadgeName,
        ub.Level AS BadgeLevel
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostTagCTE pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerDisplayName = CAST(ub.UserId AS CHAR)
    ORDER BY 
        rp.CreationDate DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerDisplayName,
    TagCount,
    UpVoteCount,
    DownVoteCount,
    COALESCE(CONCAT(BadgeName, ' (Level ', BadgeLevel, ')'), 'No Badges') AS BadgeDetails
FROM 
    BenchmarkingStats
WHERE 
    TagCount > 3 AND UpVoteCount > DownVoteCount  
ORDER BY 
    CreationDate DESC
LIMIT 10;
