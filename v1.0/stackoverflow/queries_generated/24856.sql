WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerName,
        rp.RankScore,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
        AND rp.CommentCount > 5
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.CreationDate,
    COALESCE(fp.UpVotes, 0) - COALESCE(fp.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN fp.RankScore IS NULL THEN 'No Rank'
        WHEN fp.RankScore = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId 
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12)  -- Posts that were closed, reopened or deleted
    AND ph.CreationDate >= NOW() - INTERVAL '7 days'
ORDER BY 
    NetVotes DESC,
    fp.CreationDate DESC
LIMIT 10;

-- Including a CTE for badge summary for users who own any of the filtered posts
WITH UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    INNER JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        u.Id IN (SELECT DISTINCT fp.OwnerName FROM FilteredPosts fp)
    GROUP BY 
        b.UserId
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    ub.Badges
FROM 
    FilteredPosts fp
LEFT JOIN 
    UserBadges ub ON ub.UserId = fp.OwnerName
ORDER BY 
    fp.UpVotes DESC;
