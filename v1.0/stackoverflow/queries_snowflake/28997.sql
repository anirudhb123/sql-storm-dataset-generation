
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes,
        LISTAGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(value) AS TagName, SPLIT_TO_TABLE(p.Tags, '><') AS Tag FROM Posts p) t ON TRUE
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount, 
        TotalUpVotes, 
        TotalDownVotes, 
        NetVotes, 
        TagsUsed,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    Rank, 
    UserId, 
    DisplayName, 
    Reputation, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    TotalUpVotes, 
    TotalDownVotes, 
    NetVotes, 
    TagsUsed
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
