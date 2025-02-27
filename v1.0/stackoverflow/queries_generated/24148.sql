WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
TopPosts AS (
    SELECT 
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- Latest post of each user
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(tp.Id) AS TotalPosts,
        AVG(tp.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        TopPosts tp ON tp.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalViews,
    us.TotalPosts,
    us.AverageScore,
    CASE 
        WHEN us.AverageScore IS NULL THEN 'No Score Yet'
        WHEN us.AverageScore > 50 THEN 'Expert'
        WHEN us.AverageScore BETWEEN 10 AND 50 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserRank,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Users u2 WHERE u2.LastAccessDate < NOW() - INTERVAL '1 year' AND u2.Id = us.UserId) 
        THEN 'Inactive over 1 year' 
        ELSE 'Active' 
    END AS ActivityStatus
FROM 
    UserStats us
ORDER BY 
    us.TotalPosts DESC, us.TotalViews DESC;

-- To include corner cases: handling NULLs for Users without Posts,
-- complex predicates for cases with varying lower bounds of AverageScore,
-- and ensuring edge conditions for user activity using EXISTS.
