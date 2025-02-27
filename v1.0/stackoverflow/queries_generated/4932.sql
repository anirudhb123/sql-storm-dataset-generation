WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes,
        AVG(DATEDIFF(second, p.CreationDate, GETDATE())) AS AvgPostAgeInSeconds
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            v.UserId,
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            v.UserId
    ) AS vs ON u.Id = vs.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
), TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalVotes,
        AvgPostAgeInSeconds,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    t.DisplayName,
    t.PostCount,
    t.TotalVotes,
    t.AvgPostAgeInSeconds,
    CASE 
        WHEN t.TotalVotes = 0 THEN 'No Votes'
        WHEN t.TotalVotes < 10 THEN 'Low Engagement'
        ELSE 'Active User'
    END AS EngagementLevel
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC;

SELECT 
    p.Title, 
    p.ViewCount, 
    c.Text AS CommentText, 
    et.Name AS EditType
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes et ON ph.PostHistoryTypeId = et.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE())
    AND (p.Score > 10 OR c.Id IS NOT NULL)
    AND (ph.CreationDate IS NULL OR ph.CreationDate BETWEEN p.CreationDate AND GETDATE())
ORDER BY 
    p.ViewCount DESC
LIMIT 100;

SELECT 
    a.DisplayName AS ContributorName,
    COUNT(a.Id) AS AnswerCount,
    SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
    SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
    MAX(COALESCE(ph.Comment, 'N/A')) AS LastEditComment
FROM 
    Users a
JOIN 
    Posts q ON q.OwnerUserId = a.Id AND q.PostTypeId = 1
LEFT JOIN 
    Posts ans ON ans.ParentId = q.Id AND ans.PostTypeId = 2
LEFT JOIN 
    Votes v ON v.PostId = ans.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = ans.Id
WHERE 
    a.CreationDate > '2022-01-01'
GROUP BY 
    a.DisplayName
HAVING 
    COUNT(ans.Id) >= 5
ORDER BY 
    UpVotes DESC;
