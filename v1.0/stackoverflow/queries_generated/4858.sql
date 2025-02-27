WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.BadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        rp.Score > 10 AND 
        (rp.CommentCount IS NOT NULL OR rp.BadgeCount > 0)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.AnswerCount,
    fp.CommentCount,
    fp.BadgeCount,
    CASE 
        WHEN fp.CommentCount > 5 THEN 'Highly Discussed'
        WHEN fp.BadgeCount > 0 THEN 'Recognized Contributor'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC
LIMIT 50;

-- Additionally, let's check users with the highest activity
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS ActivePosts,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id
HAVING 
    COUNT(p.Id) > 10 AND 
    SUM(v.VoteTypeId) IS NOT NULL
ORDER BY 
    ActivePosts DESC
LIMIT 10;
