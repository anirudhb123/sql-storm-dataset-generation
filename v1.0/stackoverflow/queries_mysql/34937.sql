
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        Level + 1
    FROM 
        Users U
    INNER JOIN 
        UserReputationCTE UR ON UR.Id = U.Id
    WHERE 
        U.Reputation > 1000
),
AggregateVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(av.UpVotes, 0) AS UpVotes,
        COALESCE(av.DownVotes, 0) AS DownVotes,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        AggregateVotes av ON p.Id = av.PostId
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2023-01-01' AND
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Score, pt.Name
),
HighScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CommentCount,
        UpVotes,
        DownVotes,
        PostTypeName,
        @rank := IF(@prev = PostTypeName, @rank + 1, 1) AS Rank,
        @prev := PostTypeName
    FROM 
        PostDetails, (SELECT @rank := 0, @prev := '') AS vars
    ORDER BY 
        PostTypeName, Score DESC
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Score,
    hsp.CommentCount,
    hsp.UpVotes,
    hsp.DownVotes,
    hsp.PostTypeName,
    u.Reputation AS UserReputation,
    u.DisplayName
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    Users u ON hsp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p
        WHERE 
            p.OwnerUserId = u.Id
    )
WHERE 
    hsp.Rank <= 5
ORDER BY 
    hsp.PostTypeName, hsp.Score DESC;
