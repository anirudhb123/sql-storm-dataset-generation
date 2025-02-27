WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
), 
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), 
HighlightedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.AnswerCount,
        rp.ViewCount,
        up.BadgeCount,
        pc.CommentCount,
        COALESCE(pc.Comments, 'No comments') AS Comments
    FROM 
        RankedPosts rp
    JOIN 
        UsersWithBadges up ON rp.OwnerUserId = up.UserId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.Rank <= 5 -- Get top 5 questions by score for each user
)
SELECT 
    hp.Title,
    hp.Score,
    hp.CreationDate,
    hp.AnswerCount,
    hp.ViewCount,
    hp.BadgeCount,
    hp.CommentCount,
    hp.Comments
FROM 
    HighlightedPosts hp
ORDER BY 
    hp.Score DESC, hp.BadgeCount DESC;
