WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(bp.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        WHERE 
            Date >= NOW() - INTERVAL '6 months'
        GROUP BY 
            UserId
    ) bp ON rp.OwnerUserId = bp.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.BadgeCount
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.ViewCount DESC, tp.UpVotes DESC, tp.CreationDate ASC
UNION ALL
SELECT 
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS CommentCount,
    NULL AS UpVotes,
    NULL AS DownVotes,
    COUNT(*) AS BadgeCount
FROM 
    Badges
WHERE 
    Class = 1
  AND 
    Date >= NOW() - INTERVAL '1 year'
HAVING 
    COUNT(*) > 100
ORDER BY 
    BadgeCount DESC;
