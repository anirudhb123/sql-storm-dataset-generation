
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR  
        AND p.ViewCount > 100  
),
TrendingTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag 
    FROM 
        Posts p 
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH 
        AND p.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM 
        TrendingTags 
    GROUP BY 
        Tag 
    ORDER BY 
        TagUsage DESC
    LIMIT 5  
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.OwnerName,
    tg.Tag AS TrendingTag,
    ua.DisplayName AS UserName,
    ua.QuestionsCreated,
    ua.UpVotesReceived,
    ua.DownVotesReceived
FROM 
    RankedPosts rp
JOIN 
    TagCounts tg ON rp.Tags LIKE CONCAT('%', tg.Tag, '%')
JOIN 
    UserActivities ua ON rp.OwnerName = ua.DisplayName
WHERE 
    rp.TagRank = 1  
ORDER BY 
    rp.ViewCount DESC, ua.UpVotesReceived DESC;
