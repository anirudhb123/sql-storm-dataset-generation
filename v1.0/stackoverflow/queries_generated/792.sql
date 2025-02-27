WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(AVG(v.VoteTypeId::int), 0) AS AvgVoteType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
PostStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Score,
        pd.CommentCount,
        pd.Tags,
        ur.DisplayName AS TopUser,
        ur.Reputation,
        ur.ReputationRank
    FROM 
        PostDetails pd
    JOIN 
        UserReputation ur ON pd.Score BETWEEN (ur.Reputation * 0.5) AND (ur.Reputation * 1.5)
    WHERE 
        pd.AvgVoteType > 1
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.Tags,
    ps.TopUser,
    ps.Reputation,
    ps.ReputationRank,
    CASE 
        WHEN ps.Score IS NULL THEN 'No Score'
        ELSE 'Has Score'
    END AS ScoreStatus
FROM 
    PostStats ps
LEFT JOIN 
    Posts p ON ps.PostId = p.Id
WHERE 
    ps.CommentCount > 10
ORDER BY 
    ps.ReputationRank, ps.Score DESC 
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
