WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(rp.UpVoteCount) - SUM(rp.DownVoteCount), 0) AS VoteScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBadges,
        TotalComments,
        VoteScore,
        ROW_NUMBER() OVER (ORDER BY TotalComments DESC, VoteScore DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        TotalComments > 10 
    AND 
        Reputation > 100
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalBadges,
    tu.TotalComments,
    tu.VoteScore,
    tu.UserRank
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;

-- Further analysis on posts created by top users
WITH TopUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        TopUsers tu ON p.OwnerUserId = tu.UserId
)

SELECT 
    tup.Title,
    tup.CommentCount,
    CASE
        WHEN tup.CreationDate < NOW() - INTERVAL '1 month' THEN 'Stale'
        ELSE 'Active'
    END AS PostStatus
FROM 
    TopUserPosts tup
WHERE 
    tup.CommentCount > 0
ORDER BY 
    tup.CommentCount DESC;
