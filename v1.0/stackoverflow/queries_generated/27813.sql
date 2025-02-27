WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
        JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.UserPostRank <= 5 -- Top 5 posts per user based on views
),
TagsAndBadges AS (
    SELECT 
        t.TagName,
        b.Name AS BadgeName,
        b.Class,
        b.Date AS BadgeDate
    FROM 
        Tags t
        JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
        JOIN Badges b ON b.UserId = p.OwnerUserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    STRING_AGG(DISTINCT tab.TagName, ', ') AS AssociatedTags,
    STRING_AGG(DISTINCT CONCAT(b.BadgeName, ' (Class ', b.Class, ') on ', TO_CHAR(b.BadgeDate, 'YYYY-MM-DD')), '; ') AS UserBadges
FROM 
    TopPosts tp
    LEFT JOIN TagsAndBadges tab ON tab.UserId = tp.OwnerUserId
    LEFT JOIN Badges b ON b.UserId = tp.OwnerUserId
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.ViewCount, tp.CommentCount, tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY 
    tp.ViewCount DESC;
