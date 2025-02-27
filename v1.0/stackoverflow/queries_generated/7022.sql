WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 -- Filter for users with a reputation greater than 100
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score AS PostScore,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS RecentRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Posts from the last 30 days
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    r.VoteCount,
    tc.TotalScore AS ContributorScore,
    ra.OwnerDisplayName,
    ra.PostScore,
    ra.RecentRank
FROM 
    RankedPosts r
JOIN 
    TopContributors tc ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tc.UserId)
JOIN 
    RecentActivity ra ON r.PostId = ra.PostId
WHERE 
    r.Rank = 1 -- Select only the top-ranked post for each user
ORDER BY 
    r.Score DESC, tc.TotalScore DESC;
