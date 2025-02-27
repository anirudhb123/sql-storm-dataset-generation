WITH Recent_Posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days' 
    GROUP BY 
        p.Id
),
Top_Users AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(p.Id) > 5
),
Post_History_Details AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment AS EditComment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Id IN (2, 5, 10) -- Focusing on initial body edits and closures
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVotes AS TotalUpVotes,
    rp.DownVotes AS TotalDownVotes,
    rp.CommentCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    pd.EditDate,
    pd.EditComment,
    pd.PostHistoryType
FROM 
    Recent_Posts rp
JOIN 
    Top_Users tu ON rp.UserPostRank = 1 AND rp.OwnerUserId = tu.UserId
LEFT JOIN 
    Post_History_Details pd ON rp.PostId = pd.PostId
WHERE 
    rp.Score > 0
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

-- This query does the following:
-- 1. It selects posts created in the last 30 days and aggregates votes and comments.
-- 2. It identifies users with top scores based on their posts.
-- 3. It retrieves important post history details like edits and closure reasons.
-- 4. Finally, it combines these with a filter for positive scores and returns the 100 highest-scoring posts along with user info and edit history.
