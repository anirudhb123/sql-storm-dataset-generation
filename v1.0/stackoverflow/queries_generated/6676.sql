WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY 
        p.Id
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.VoteCount
FROM 
    UserReputations ur
JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank <= 5 -- Get the top 5 posts per user
ORDER BY 
    ur.Reputation DESC, rp.Score DESC;
