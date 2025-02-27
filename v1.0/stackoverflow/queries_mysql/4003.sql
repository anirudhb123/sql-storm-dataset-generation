
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        @Rank := @Rank + 1 AS Rank
    FROM Users, (SELECT @Rank := 0) AS r
    ORDER BY Reputation DESC
),
TopUsers AS (
    SELECT UserId 
    FROM UserReputation 
    WHERE Rank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVotes,
        COALESCE(v.DownVoteCount, 0) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS IsAccepted
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS Count 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR 
          AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.IsAccepted,
        @PostRank := @PostRank + 1 AS PostRank
    FROM PostDetails pd, (SELECT @PostRank := 0) AS r
    WHERE pd.CommentCount > 5
    ORDER BY (pd.UpVotes - pd.DownVotes) DESC
)

SELECT 
    u.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.IsAccepted
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
JOIN 
    Posts p ON u.Id = p.OwnerUserId
JOIN 
    TopPosts tp ON p.Id = tp.PostId
WHERE 
    tp.PostRank <= 5
ORDER BY 
    u.Reputation DESC, tp.UpVotes - tp.DownVotes DESC;
