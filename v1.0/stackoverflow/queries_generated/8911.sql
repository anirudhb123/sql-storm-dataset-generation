WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN v.Id IS NOT NULL THEN 1 END) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvote
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUserPosts AS (
    SELECT 
        rp.OwnerUserId,
        u.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TotalComments,
        rp.TotalVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserPostRank = 1
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(tp.TotalVotes) AS TotalVotes,
    SUM(tp.TotalComments) AS TotalComments,
    COUNT(tp.PostId) AS NumberOfPosts,
    MIN(tp.CreationDate) AS EarliestPost,
    MAX(tp.CreationDate) AS LatestPost,
    AVG(tp.Score) AS AveragePostScore
FROM 
    Users u
JOIN 
    TopUserPosts tp ON u.Id = tp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalVotes DESC,
    NumberOfPosts DESC;
