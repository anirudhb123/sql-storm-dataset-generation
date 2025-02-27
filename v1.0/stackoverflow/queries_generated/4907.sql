WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        UserId, 
        QuestionCount, 
        AnswerCount, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.Location,
    u.Views,
    t.QuestionCount,
    t.AnswerCount,
    t.TotalScore,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    COALESCE(b.Class, 0) AS BadgeClass
FROM 
    TopUsers t
JOIN 
    Users u ON u.Id = t.UserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Class = 1
WHERE 
    t.Rank <= 10
ORDER BY 
    t.TotalScore DESC;

WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT ta.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS ta(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Tags,
    COALESCE(COUNT(c.Id), 0) AS CommentCount
FROM 
    RecentPosts rp
LEFT JOIN 
    Comments c ON c.PostId = rp.Id
GROUP BY 
    rp.Id
ORDER BY 
    rp.LastActivityDate DESC;
