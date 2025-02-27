
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
      SELECT 9 UNION ALL SELECT 10
    ) n 
    WHERE 
        p.PostTypeId = 1  
        AND n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(PostId) AS PostCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount >= 10  
),
UsersEngaged AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ue.QuestionCount,
        ue.UpVotes,
        ue.DownVotes
    FROM 
        Users u
    JOIN 
        UsersEngaged ue ON u.Id = ue.OwnerUserId
)
SELECT 
    upr.DisplayName,
    upr.Reputation,
    upr.QuestionCount,
    upr.UpVotes,
    upr.DownVotes,
    pt.Tag AS PopularTag
FROM 
    UserReputation upr
JOIN 
    PopularTags pt ON upr.QuestionCount >= 5  
ORDER BY 
    upr.Reputation DESC, upr.QuestionCount DESC;
