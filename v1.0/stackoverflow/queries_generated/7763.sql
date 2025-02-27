WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(vote.VoteTypeId = 2) AS UpVotes,  -- Counting UpVotes
        SUM(vote.VoteTypeId = 3) AS DownVotes  -- Counting DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Considering posts created in the last year
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation ur
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.ViewCount > 100  -- Filtering for popular posts
WHERE 
    rp.Score > 10 -- Only include high-scoring posts
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 10;
