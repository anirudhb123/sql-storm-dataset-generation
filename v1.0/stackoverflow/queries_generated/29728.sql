WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- only questions
        AND p.CreationDate >= '2022-01-01'  -- created in the year 2022 or later
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.*, 
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        RankedPosts rp
        LEFT JOIN Votes v ON rp.PostId = v.PostId
    WHERE 
        rp.TagRank <= 5  -- top 5 posts by tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.ViewCount, rp.Score, 
        rp.OwnerDisplayName, rp.TagRank
), 
PostDetails AS (
    SELECT 
        tp.*,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames,
        STRING_AGG(DISTINCT h.PostHistoryTypeId, ', ') AS HistoryTypes
    FROM 
        TopPosts tp
        LEFT JOIN Badges b ON tp.OwnerDisplayName = b.UserId -- assuming DisplayName maps to UserId in Badges context
        LEFT JOIN PostHistory h ON tp.PostId = h.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.Tags, tp.CreationDate, tp.ViewCount, tp.Score, 
        tp.OwnerDisplayName, tp.VoteCount
)

SELECT 
    PostId, 
    Title, 
    Tags, 
    CreationDate, 
    ViewCount, 
    Score, 
    OwnerDisplayName, 
    VoteCount, 
    BadgeNames,
    HistoryTypes
FROM 
    PostDetails
ORDER BY 
    Score DESC, 
    ViewCount DESC;
