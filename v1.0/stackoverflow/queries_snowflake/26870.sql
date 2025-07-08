
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(value) AS Tag
    FROM 
        Posts p,
        TABLE(FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) AS t
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
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
), TopUsers AS (
    SELECT 
        ue.UserId,
        ue.QuestionsAsked,
        ue.CommentsMade,
        ue.UpVotesReceived,
        ue.DownVotesReceived,
        ue.Reputation
    FROM 
        UserEngagement ue
    WHERE 
        ue.Reputation > 1000 
    ORDER BY 
        ue.UpVotesReceived DESC
    LIMIT 10 
), TagPopularity AS (
    SELECT 
        tc.Tag,
        tc.TagFrequency,
        ROW_NUMBER() OVER (ORDER BY tc.TagFrequency DESC) AS Rank
    FROM 
        TagCounts tc
    WHERE 
        tc.TagFrequency > 1 
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
        WHERE p.Tags LIKE '%' || tp.Tag || '%'
    )
ORDER BY 
    tu.UpVotesReceived DESC, 
    tp.TagFrequency DESC;
