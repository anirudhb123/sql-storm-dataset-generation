WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  -- Questions and Answers only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.TotalPosts,
    us.TotalScore,
    us.TotalComments,
    RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank,
    RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.Reputation DESC, us.TotalScore DESC
LIMIT 50;
