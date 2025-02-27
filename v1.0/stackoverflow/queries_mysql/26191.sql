
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ph.CreationDate AS LastEditDate,
        p.ViewCount,
        CHAR_LENGTH(REPLACE(REPLACE(p.Tags, '<', ''), '>', '')) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 /* Questions only */
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, u.Reputation, ph.CreationDate
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TagCount DESC, ViewCount DESC, LastEditDate DESC) AS Rank
    FROM 
        FilteredPosts
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Reputation,
        ViewCount,
        TagCount,
        LastEditDate,
        CommentCount,
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Reputation,
    tp.ViewCount,
    tp.TagCount,
    tp.LastEditDate,
    tp.CommentCount,
    tp.BadgeCount,
    (SELECT 
         GROUP_CONCAT(DISTINCT c.UserDisplayName SEPARATOR ', ') 
     FROM 
         Comments c 
     WHERE 
         c.PostId = tp.PostId) AS Commenters
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;
