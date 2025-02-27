WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 
            0
        ) AS Upvotes,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 
            0
        ) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- In the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Upvotes,
        rp.Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Upvotes,
    tp.Downvotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)) AS UserBadges,
    (SELECT ARRAY_AGG(DISTINCT t.TagName) FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(translate(tp.Tags, '<>', ' '), ' '::text)::int[]))) AS TagsUsed
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
