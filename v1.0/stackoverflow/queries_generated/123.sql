WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CASE 
            WHEN Reputation >= 1000 THEN 'High Reputation'
            WHEN Reputation >= 100 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationLevel
    FROM Users
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.CommentCount,
        ps.VoteCount,
        ps.Upvotes,
        ps.Downvotes,
        ur.ReputationLevel
    FROM PostSummary ps
    JOIN UserReputation ur ON ps.PostId IN (SELECT id FROM Posts WHERE OwnerUserId = ur.Id)
    WHERE ps.RowNum = 1
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.Upvotes,
    tp.Downvotes,
    tp.ReputationLevel,
    CASE 
        WHEN tp.ReputationLevel = 'High Reputation' AND tp.Upvotes > 10 THEN 'Highly Rated Users'
        WHEN tp.ReputationLevel = 'Medium Reputation' AND tp.Upvotes BETWEEN 5 AND 10 THEN 'Moderately Rated Users'
        ELSE 'Others'
    END AS UserCategory
FROM TopPosts tp
WHERE tp.ViewCount >= 100
ORDER BY tp.ViewCount DESC;
