WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount, 
        NetVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalReport AS (
    SELECT 
        tp.*,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        TopPosts tp
    LEFT JOIN 
        UserBadges ub ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
)

SELECT 
    PostId,
    Title,
    Score,
    CreationDate,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    NetVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalReport
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 20;
