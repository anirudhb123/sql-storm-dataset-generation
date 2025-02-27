-- Performance Benchmarking SQL Query

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count of Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.Questions,
    u.Answers,
    u.UpVotes,
    u.DownVotes,
    p.PostId,
    p.EditCount,
    p.EditorCount
FROM 
    UserStats u
JOIN 
    PostHistoryStats p ON u.UserId = p.PostId -- assuming we want to join on UserId being matched with posts' owner Id
ORDER BY 
    u.Reputation DESC, u.PostCount DESC;
