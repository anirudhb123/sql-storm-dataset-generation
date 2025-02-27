WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseVoteCount,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.UpVoteCount DESC) AS PostRank
    FROM 
        PostStats ps
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.ReputationRank,
    ur.BadgeCount,
    tp.PostId,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.CloseVoteCount
FROM 
    UserReputation ur
LEFT JOIN 
    TopPosts tp ON ur.UserId = tp.OwnerUserId AND tp.PostRank = 1
WHERE 
    ur.Reputation IS NOT NULL
    AND (ur.Reputation > 100 OR ur.BadgeCount > 5)
ORDER BY 
    ur.Reputation DESC, tp.UpVoteCount DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

-- This query retrieves a ranked list of users with significant reputation and badge counts. 
-- It also associates each user with their top post (based on upvotes) in the last year, 
-- while skipping the first 5 results and fetching the next 10, creating a paginated list.

