WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.Score,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    ub.BadgeCount,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount, -- Assuming VoteTypeId 2 is UpMod
    SUM(v.VoteTypeId = 3) AS DownVoteCount -- Assuming VoteTypeId 3 is DownMod
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
LEFT JOIN 
    UserBadges ub ON tp.OwnerUserId = ub.UserId
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.Score, ub.BadgeCount
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC;
