WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(b.Id), 0) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON c.PostId = tp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = tp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.ViewCount, tp.Score
)
SELECT 
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ARRAY_TO_STRING(ps.TagsArray, ', ') AS Tags,
    ps.BadgeCount
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
