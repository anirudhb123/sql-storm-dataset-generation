
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0
        ) AS UpVoteCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0
        ) AS DownVoteCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.Score IS NOT NULL
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.LastAccessDate) AS LastAccess
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.PostTypeId,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    ts.TagCount,
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'High Rep User'
        WHEN ur.Reputation BETWEEN 500 AND 1000 THEN 'Medium Rep User'
        ELSE 'Low Rep User'
    END AS UserCategory,
    COALESCE(ts.TagName, 'No Tags') AS RelevantTag
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON FIND_IN_SET(ts.TagName, REPLACE(rp.Tags, '>', ',')) > 0
LEFT JOIN 
    Users u ON u.Id = rp.PostId
LEFT JOIN 
    UserReputation ur ON ur.UserId = u.Id
WHERE 
    rp.RankScore <= 10
    AND (ur.Reputation IS NULL OR ur.Reputation > 500)
ORDER BY 
    rp.Score DESC, ur.Reputation DESC, rp.CreationDate DESC;
