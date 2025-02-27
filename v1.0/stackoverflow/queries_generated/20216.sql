WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(b.Date, p.CreationDate) AS EffectiveDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId AND b.Class = 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE WHEN rp.Rank = 1 THEN 'Top Post' ELSE 'Regular Post' END AS PostCategory 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year') 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.PostCategory,
    CASE 
        WHEN fp.UpVotes IS NULL THEN 'No UpVotes'
        WHEN fp.DownVotes IS NULL AND fp.UpVotes > 10 THEN 'Highly Rated'
        ELSE 'Standard Post'
    END AS PostStatus
FROM 
    FilteredPosts fp
WHERE 
    fp.PostCategory = 'Top Post' OR (fp.PostCategory = 'Regular Post' AND fp.UpVotes - fp.DownVotes > 5)
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;

-- Union of post-related statistics
UNION ALL

SELECT 
    'Post Statistics Summary' AS SummaryType,
    COUNT(*) AS TotalPosts,
    COUNT(DISTINCT OwnerUserId) AS UniqueAuthors,
    SUM(Score) AS TotalScore,
    AVG(Score) AS AverageScore
FROM 
    Posts
WHERE 
    CreationDate >= NOW() - INTERVAL '1 year';

-- Example of outer join with NULL logic on badges
LEFT JOIN (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
) ub ON fp.OwnerUserId = ub.UserId

