WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT * FROM STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tagArr ON TRUE
    LEFT JOIN 
        Tags t ON tagArr.value = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        rp.CommentCount,
        ROW_NUMBER() OVER (ORDER BY rp.Rank) AS PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostWithBadges AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        tp.Tags,
        tp.CommentCount,
        b.Id AS BadgeId,
        b.Name AS BadgeName,
        b.Class
    FROM 
        TopPosts tp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.ViewCount,
    pwb.Score,
    pwb.Tags,
    pwb.CommentCount,
    CONCAT('Badge: ', COALESCE(pwb.BadgeName, 'No Badge')) AS BadgeDetails,
    CASE 
        WHEN pwb.Class = 1 THEN 'Gold'
        WHEN pwb.Class = 2 THEN 'Silver'
        WHEN pwb.Class = 3 THEN 'Bronze'
        ELSE 'No Badge' 
    END AS BadgeClass
FROM 
    PostWithBadges pwb
ORDER BY 
    pwb.Score DESC, pwb.ViewCount DESC;
