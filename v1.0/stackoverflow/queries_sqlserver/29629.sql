
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        STRING_AGG(DISTINCT p.Id, ',') AS PostIds 
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
    Users u ON u.Location LIKE '%' + ts.Tag + '%' 
JOIN 
    UserReputation ur ON u.Id = ur.UserId
ORDER BY 
    ts.TagCount DESC, ur.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
