WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.OwnerUserId = b.UserId AND b.Date >= NOW() - INTERVAL '1 year'
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    STRING_AGG(tag.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(tp.Title, ' ')) AS TagName
    ) tag ON tag.TagName IS NOT NULL
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.BadgeName, tp.BadgeClass
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;

WITH RecentVotes AS (
    SELECT 
        v.PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        v.PostId, vt.Name
),
VoteSummary AS (
    SELECT 
        rv.PostId,
        SUM(CASE WHEN rv.VoteType = 'UpMod' THEN rv.VoteCount ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN rv.VoteType = 'DownMod' THEN rv.VoteCount ELSE 0 END) AS DownVotes
    FROM 
        RecentVotes rv
    GROUP BY 
        rv.PostId
)
SELECT 
    tp.*,
    vs.UpVotes,
    vs.DownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    VoteSummary vs ON tp.PostId = vs.PostId
WHERE 
    tp.CommentCount > 10 OR tp.Score > 20
ORDER BY 
    COALESCE(vs.UpVotes, 0) - COALESCE(vs.DownVotes, 0) DESC
LIMIT 20;
