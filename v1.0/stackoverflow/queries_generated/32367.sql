WITH RecursivePostStats AS (
    -- Common Table Expression to retrieve post statistics
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
UserBadges AS (
    -- CTE to gather user approved badges along with reputation
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        CASE 
            WHEN u.Reputation > 1000 THEN 'Gold'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeTier
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    -- CTE to select the top-rated posts based on combined score metrics
    SELECT 
        ps.PostId,
        ps.UpVotes, 
        ps.DownVotes,
        ps.CommentCount,
        ps.EditCount,
        u.Reputation AS UserReputation,
        u.BadgeCount,
        u.BadgeTier
    FROM 
        RecursivePostStats ps
    JOIN 
        Users u ON ps.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    WHERE 
        ps.UpVotes - ps.DownVotes > 10 -- Filtering condition for high engagement posts
)
SELECT 
    tp.PostId,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.EditCount,
    tp.UserReputation,
    tp.BadgeCount,
    tp.BadgeTier
FROM 
    TopPosts tp
WHERE 
    tp.UserReputation IS NOT NULL
ORDER BY 
    tp.UpVotes DESC, tp.EditCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY; -- Pagination to get top 50 posts
