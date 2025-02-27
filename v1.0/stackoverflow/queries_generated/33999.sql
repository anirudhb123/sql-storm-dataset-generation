WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
), UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN rp.RowNum = 1 THEN 1 END), 0) AS RecentPostsCount,
        COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(rp.UpVotes) - SUM(rp.DownVotes), 0) AS VotesNet
    FROM 
        Users u
    LEFT JOIN 
        RecursivePosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        RecentPostsCount,
        TotalComments,
        VotesNet,
        RANK() OVER (ORDER BY VotesNet DESC, Reputation DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.RecentPostsCount,
    tu.TotalComments,
    tu.VotesNet,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top Contributor'
        WHEN tu.UserRank > 10 AND tu.UserRank <= 50 THEN 'Contributor'
        ELSE 'New User'
    END AS UserCategory
FROM 
    TopUsers tu
WHERE 
    tu.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    tu.VotesNet DESC, tu.Reputation DESC;

-- Below query for a historical context of the questions edited or closed
SELECT 
    p.Title,
    p.CreationDate,
    ph.CreationDate AS HistoryDate,
    pht.Name AS HistoryType,
    u.DisplayName AS EditorDisplayName
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 24) -- 10=Post Closed, 11=Post Reopened, 24=Suggested Edit Applied
ORDER BY 
    p.CreationDate DESC, ph.CreationDate DESC;

-- Analyzing tag popularity and user engagement
SELECT 
    t.TagName,
    COUNT(DISTINCT p.Id) AS PostsCount,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentsScore,
    COALESCE(AVG(u.Reputation), 0) AS AverageUserReputation
FROM 
    Tags t
LEFT JOIN 
    Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
GROUP BY 
    t.TagName
HAVING 
    COUNT(DISTINCT p.Id) > 10 -- Tags with more than 10 posts
ORDER BY 
    TotalCommentsScore DESC, PostsCount DESC;
