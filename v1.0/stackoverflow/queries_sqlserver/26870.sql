
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        LTRIM(RTRIM(value)) AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
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
)
SELECT TOP 10
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
    (SELECT 
         tc.Tag,
         tc.TagFrequency,
         ROW_NUMBER() OVER (ORDER BY tc.TagFrequency DESC) AS Rank
     FROM 
         TagCounts tc
     WHERE 
         tc.TagFrequency > 1 
    ) tp ON tu.UserId IN (
        SELECT DISTINCT p.OwnerUserId 
        FROM Posts p 
        WHERE p.Tags LIKE '%' + tp.Tag + '%'
    )
ORDER BY 
    tu.UpVotesReceived DESC, 
    tp.TagFrequency DESC;
