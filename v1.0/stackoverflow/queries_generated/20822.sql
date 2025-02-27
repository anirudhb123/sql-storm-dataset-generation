WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.UpVotes IS NULL THEN 0 ELSE p.UpVotes END) AS TotalUpVotes,
        SUM(CASE WHEN p.DownVotes IS NULL THEN 0 ELSE p.DownVotes END) AS TotalDownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
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
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(u.PostCount, 0) AS TotalPosts,
    COALESCE(u.QuestionCount, 0) AS TotalQuestions,
    COALESCE(u.AnswerCount, 0) AS TotalAnswers,
    COALESCE(u.TotalUpVotes, 0) AS UpVotes,
    COALESCE(u.TotalDownVotes, 0) AS DownVotes,
    COALESCE(u.BadgeCount, 0) AS Badges,
    CASE 
        WHEN u.Rank IS NULL THEN 'Unranked'
        ELSE CAST(u.Rank AS VARCHAR)
    END AS UserRank
FROM 
    TopUsers u
WHERE 
    EXISTS (
        SELECT 1 
        FROM Posts p
        WHERE p.OwnerUserId = u.UserId AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    )
ORDER BY 
    u.Rank
FETCH FIRST 10 ROWS ONLY;

-- Retrieving posts with specfic conditions involving subqueries and null checks
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE((
        SELECT STRING_AGG(c.Text, '; ') 
        FROM Comments c 
        WHERE c.PostId = p.Id
    ), 'No comments') AS Comments,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ) THEN 'Upvoted'
        ELSE 'Not Upvoted'
    END AS VoteStatus,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS Status,
    COALESCE(
        (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)), 0
    ) AS CloseOpenCount
FROM 
    Posts p
WHERE 
    p.ViewCount > 1000 
    AND (p.Score IS NULL OR p.Score > 0) 
    AND p.CreationDate < CURRENT_DATE - INTERVAL '30 days'
ORDER BY 
    p.Score DESC
FETCH FIRST 5 ROWS ONLY;

-- Union to combine distinct post titles with and without specific tags
SELECT DISTINCT 
    p.Title 
FROM 
    Posts p
WHERE 
    p.Tags ILIKE '%sql%'
UNION
SELECT DISTINCT 
    p.Title 
FROM 
    Posts p
WHERE 
    p.Tags IS NULL
ORDER BY 
    Title;

-- Example showing the use of outer join and correlated subquery with cautious NULL logic
SELECT 
    u.DisplayName,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.CreatedAt > CURRENT_TIMESTAMP - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(p.Id) > 0 
ORDER BY 
    BadgeCount DESC, TotalPosts DESC;
