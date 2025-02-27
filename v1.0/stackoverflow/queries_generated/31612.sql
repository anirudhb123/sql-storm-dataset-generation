WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN <= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostLinksCTE AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedLinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    ua.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount,
    ua.BadgeCount,
    COALESCE(plc.RelatedLinkCount, 0) AS RelatedLinkCount,
    CASE 
        WHEN tp.Score > 10 THEN 'High Score'
        WHEN tp.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    PostLinksCTE plc ON tp.PostId = plc.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
