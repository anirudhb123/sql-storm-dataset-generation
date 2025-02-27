
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        GROUP_CONCAT(DISTINCT p.Id) AS PostIds 
    FROM 
        ProcessedTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS AnsweredQuestions,
        SUM(CASE WHEN v.voteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.voteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2  
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ts.Tag,
    ts.TagCount,
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.AnsweredQuestions,
    ur.UpVotes,
    ur.DownVotes
FROM 
    TagStatistics ts
JOIN 
    Users u ON u.Location LIKE CONCAT('%', ts.Tag, '%') 
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    ts.TagCount DESC, ur.Reputation DESC
LIMIT 10;
