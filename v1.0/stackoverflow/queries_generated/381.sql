WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate,
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCEN(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(vote.BountyAmount, 0)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId AND vote.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id
),
TopUserPosts AS (
    SELECT 
        up.UserId, 
        up.TotalPosts, 
        up.TotalScore, 
        up.AverageBounty, 
        rp.PostId, 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Top Post' 
            ELSE 'Other Post' 
        END AS PostType
    FROM 
        UserStats up
    JOIN 
        RankedPosts rp ON up.UserId = rp.OwnerUserId
    WHERE 
        up.TotalPosts > 5
)
SELECT 
    tup.UserId, 
    tup.DisplayName, 
    tup.TotalPosts, 
    tup.TotalScore, 
    tup.AverageBounty, 
    tup.PostId, 
    tup.Title, 
    tup.CreationDate, 
    tup.ViewCount, 
    tup.PostType,
    COALESCE((SELECT COUNT(c.Id) 
              FROM Comments c 
              WHERE c.PostId = tup.PostId), 0) AS CommentCount,
    COALESCE((SELECT STRING_AGG(CONCAT('User:', u.DisplayName, ' Vote:', vt.Name), ', ') 
              FROM Votes v 
              JOIN VoteTypes vt ON v.VoteTypeId = vt.Id 
              JOIN Users u ON v.UserId = u.Id
              WHERE v.PostId = tup.PostId), 'No Votes') AS VotesInfo
FROM 
    TopUserPosts tup
ORDER BY 
    tup.TotalScore DESC, 
    tup.CreationDate DESC;
