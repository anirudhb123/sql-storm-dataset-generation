
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(a.Id) AS AnswerCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) AS numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
FeaturedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT b.Id) > 1 AND SUM(u.UpVotes) > SUM(u.DownVotes)
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.AnswerCount,
        rp.Tags,
        fu.DisplayName AS FeaturedAuthor
    FROM 
        RankedPosts rp
    JOIN 
        FeaturedUsers fu ON rp.UserPostRank = 1 AND rp.Author = fu.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.AnswerCount,
    ps.Tags,
    ps.FeaturedAuthor
FROM 
    PostStatistics ps
ORDER BY 
    ps.CreationDate DESC;
