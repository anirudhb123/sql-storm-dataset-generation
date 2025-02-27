WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopPostUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, Reputation DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.CommentCount,
    COALESCE((SELECT COUNT(*) FROM Posts p1 WHERE p1.OwnerUserId = u.UserId AND p1.AcceptedAnswerId IS NOT NULL), 0) AS AcceptedAnswers,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    TopPostUsers u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    unnest(string_to_array(p.Tags, '<>')) AS t(TagName)
WHERE 
    u.Rank <= 10
GROUP BY 
    u.DisplayName, u.Reputation, u.PostCount, u.CommentCount
ORDER BY 
    u.PostCount DESC, u.Reputation DESC;
