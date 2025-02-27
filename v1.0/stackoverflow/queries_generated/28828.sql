WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount,
        (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ) AS UpVoteCount,
        (
            SELECT COUNT(*)
            FROM Votes v
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ) AS DownVoteCount,
        RANK() OVER (ORDER BY 
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) - 
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) DESC
        ) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Questions only
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount - rp.DownVoteCount AS NetVoteCount, 
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    LATERAL (
        SELECT 
            TRIM(UNNEST(STRING_TO_ARRAY(rp.Tags, '><'))) AS TagName
    ) t ON TRUE
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate
HAVING 
    rp.Rank <= 10
ORDER BY 
    NetVoteCount DESC, rp.CommentCount DESC;
