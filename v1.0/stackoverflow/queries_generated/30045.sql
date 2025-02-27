WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        1 AS Level
    FROM Users u
    WHERE u.Id IN (SELECT DISTINCT UserId FROM Votes)
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation + (SELECT COALESCE(SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE -1 END), 0) FROM Votes v JOIN VoteTypes vt ON v.VoteTypeId = vt.Id WHERE v.UserId = u.Id) AS Reputation,
        u.CreationDate,
        u.DisplayName,
        u.Views * 1.1,  -- Assume views increase by 10% per level
        u.UpVotes * (1 + (0.1 * Level)),  -- Increase upvotes by 10% for each recursive call
        u.DownVotes * (1 + (0.05 * Level)),  
        Level + 1
    FROM Users u
    JOIN RecursiveUserStats rus ON u.Id = rus.UserId
    WHERE Level < 5  -- Limit the recursion depth
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.voteTypeId = 2 THEN 1 ELSE -1 END) AS NetVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY p.Id
),

FinalStats AS (
    SELECT 
        rus.UserId,
        rus.DisplayName,
        rus.Reputation,
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY rus.UserId ORDER BY pd.Score DESC) as Rank
    FROM RecursiveUserStats rus
    JOIN PostDetails pd ON rus.UserId = pd.OwnerUserId
)

SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.Reputation,
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    fs.Rank
FROM FinalStats fs
WHERE fs.Reputation > 1000
AND fs.Rank <= 3  -- Top 3 posts per user
ORDER BY fs.Reputation DESC, fs.ViewCount DESC;
