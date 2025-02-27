
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        u.Views,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes, u.Views
),
TopTaggedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        GROUP_CONCAT(DISTINCT LEFT(t.TagName, 20) ORDER BY t.TagName SEPARATOR ', ') AS TopTags
    FROM 
        Posts p
    JOIN 
        Tags t ON LOCATE(t.TagName, p.Tags) > 0
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Tags
),
HighRatedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score >= 10
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Views,
    us.AnswerCount,
    us.QuestionCount,
    trp.PostId,
    trp.Title AS HighRatedPostTitle,
    trp.Score AS HighRatedPostScore,
    trp.OwnerName,
    tt.TopTags
FROM 
    UserStats us
LEFT JOIN 
    HighRatedPosts trp ON us.QuestionCount >= 5
LEFT JOIN 
    TopTaggedPosts tt ON tt.Id = trp.PostId
ORDER BY 
    us.Reputation DESC, us.Views DESC
LIMIT 20;
