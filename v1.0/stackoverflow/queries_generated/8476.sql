WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, 
        rp.ViewCount, rp.OwnerDisplayName, rp.CommentCount,
        rp.UpVoteCount, rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)

SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
               FROM STRING_TO_ARRAY(tp.Tags, ',') AS tags ON TRUE
               JOIN Tags t ON t.Id = tags::int 
               WHERE t.Id IS NOT NULL), 'No Tags') AS RelatedTags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
