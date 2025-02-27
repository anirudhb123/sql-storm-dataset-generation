
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
TaggedPosts AS (
    SELECT 
        hp.*,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        HighScorePosts hp
    JOIN 
        (SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(hp.Body, '<tag>', -i), '<tag>', 1)) AS TagName
         FROM 
            (SELECT 
                @row := @row + 1 AS i
             FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION 
                 SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t,
                (SELECT @row := 0) r
            ) numbers
         WHERE 
            CHAR_LENGTH(hp.Body) - CHAR_LENGTH(REPLACE(hp.Body, '<tag>', '')) >= i - 1) t
        ) t ON CHAR_LENGTH(hp.Body) - CHAR_LENGTH(REPLACE(hp.Body, '<tag>', '')) > 0
    GROUP BY 
        hp.PostId, hp.Title, hp.Body, hp.CreationDate, hp.ViewCount, hp.Score, hp.OwnerDisplayName, hp.CommentCount
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate,
    tp.Tags,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            Votes v
        WHERE 
            v.PostId = tp.PostId AND v.VoteTypeId = 2 
    ), 0) AS UpVotes
FROM 
    TaggedPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
