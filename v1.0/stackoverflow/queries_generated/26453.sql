WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.OwnerDisplayName, 'Community User') AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount  -- UpMod votes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- posts created in the last year
        AND p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerDisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.TagCount,
        rp.CommentCount,
        rp.UpVoteCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.UpVoteCount DESC, rp.CommentCount DESC) AS Rank
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.TagCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.Rank,
    pht.Name AS PostHistoryType,
    COUNT(DISTINCT ph.Id) AS HistoryEventCount
FROM 
    TopPosts tp
    LEFT JOIN PostHistory ph ON tp.PostId = ph.PostId
    LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    tp.Rank <= 10  -- Get only top 10 ranked posts
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.TagCount, tp.CommentCount, tp.UpVoteCount, tp.Rank, pht.Name
ORDER BY 
    tp.Rank;
