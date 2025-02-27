
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT a.method_number AS n 
         FROM (SELECT @row := @row + 1 AS method_number 
               FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                     UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
                     UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t,
               (SELECT @row := 0) r) a) n
    WHERE 
        n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1
    AND 
        p.PostTypeId = 1 
), TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        ParsedTags
    GROUP BY 
        Tag
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), TopUsers AS (
    SELECT 
        ue.UserId,
        ue.QuestionsAsked,
        ue.CommentsMade,
        ue.UpVotesReceived,
        ue.DownVotesReceived,
        u.Reputation
    FROM 
        UserEngagement ue
    JOIN 
        Users u ON ue.UserId = u.Id
    WHERE 
        u.Reputation > 1000 
    ORDER BY 
        ue.UpVotesReceived DESC
    LIMIT 10 
), TagPopularity AS (
    SELECT 
        tc.Tag,
        tc.TagFrequency,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts tc, (SELECT @rank := 0) r
    WHERE 
        tc.TagFrequency > 1 
    ORDER BY 
        tc.TagFrequency DESC
)
SELECT 
    tu.UserId,
    tu.QuestionsAsked,
    tu.CommentsMade,
    tu.UpVotesReceived,
    tu.DownVotesReceived,
    tu.Reputation,
    tp.Tag,
    tp.TagFrequency
FROM 
    TopUsers tu
JOIN 
    TagPopularity tp ON tu.UserId IN (
        SELECT DISTINCT p.OwnerUserId 
        FROM Posts p 
        WHERE p.Tags LIKE CONCAT('%', tp.Tag, '%')
    )
ORDER BY 
    tu.UpVotesReceived DESC, 
    tp.TagFrequency DESC;
