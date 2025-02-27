WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, u.DisplayName
), RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.CommentCount,
    r.UpVotes,
    r.DownVotes,
    r.PostType,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    RecentPosts r
LEFT JOIN 
    Badges b ON r.OwnerDisplayName = b.UserId
ORDER BY 
    r.UpVotes DESC, r.CommentCount DESC;
