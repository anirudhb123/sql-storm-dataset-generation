WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostBadges AS (
    SELECT 
        bp.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Posts p ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        bp.UserId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    pv.UpVotes,
    pv.DownVotes,
    COALESCE(pb.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
LEFT JOIN 
    PostBadges pb ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = pb.UserId)
ORDER BY 
    tp.Score DESC;
