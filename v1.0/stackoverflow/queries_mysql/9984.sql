
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId,
        GROUP_CONCAT(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1) TagName
         FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
             UNION ALL SELECT 10) numbers 
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1) t 
        ON true
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type_id := -1) r
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, u.Reputation, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerReputation,
        rp.Rank,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    tp.CreationDate,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    tp.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteStats pvs ON tp.PostId = pvs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
