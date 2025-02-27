
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(t.TagName) AS TagsArray,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            p.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            Posts p 
        INNER JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON p.Id = t.Id
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagsArray,
        rp.CommentCount,
        rp.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS ScoreRank
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank <= 50  
)
SELECT
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.TagsArray,
    tp.CommentCount,
    tp.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM
    TopPosts tp
JOIN
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN (
    SELECT
        UserId,
        COUNT(*) AS BadgeCount
    FROM
        Badges
    WHERE
        Class = 1  
    GROUP BY
        UserId
) b ON b.UserId = u.Id
WHERE
    EXISTS (
        SELECT 1 FROM Votes v
        WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2  
    )
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
