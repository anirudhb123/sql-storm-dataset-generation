WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        AVG(voteValue) AS AverageVote,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, 
                SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 
                         WHEN vt.Name = 'DownMod' THEN -1 
                         ELSE 0 END) AS voteValue 
         FROM Votes v
         JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY PostId) voteSummary ON p.Id = voteSummary.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostUserInteraction AS (
    SELECT 
        tp.PostId,
        u.DisplayName,
        ub.BadgeCount
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.AverageVote,
    u.DisplayName AS Owner,
    COALESCE(b.BadgeCount, 0) AS TotalBadges
FROM 
    PostUserInteraction p
LEFT JOIN 
    UserBadges b ON p.OwnerUserId = b.UserId
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
