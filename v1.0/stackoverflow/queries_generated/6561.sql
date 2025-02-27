WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.UpvoteCount,
    tp.DownvoteCount,
    COALESCE(NULLIF(t.TagName, ''), 'No Tags') AS TagName
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            STRING_AGG(t.TagName, ', ') AS TagName
        FROM 
            UNNEST(string_to_array(substring(tp.Tags, 2, length(tp.Tags)-2), '> <'))::varchar[]) AS tag_name
        JOIN 
            Tags t ON t.TagName = tag_name
    ) t ON TRUE
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
