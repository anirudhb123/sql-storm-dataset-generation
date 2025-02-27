WITH RankedUsers AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(*) 
         FROM Votes v2 
         WHERE v2.PostId = p.Id AND v2.VoteTypeId IN (6, 10, 12)) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserPostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    t.PostId,
    t.Title,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    t.CloseVoteCount,
    COALESCE(up.PostCount, 0) AS UserPostCount
FROM 
    RankedUsers u
JOIN 
    TopPosts t ON u.Id = t.OwnerUserId
LEFT JOIN 
    UserPostCounts up ON u.Id = up.OwnerUserId
WHERE 
    t.CloseVoteCount = 0
ORDER BY 
    t.UpVotes DESC, t.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
