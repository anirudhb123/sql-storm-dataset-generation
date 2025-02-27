WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,  -- Count of Up votes
        SUM(v.VoteTypeId = 3) AS DownVoteCount,  -- Count of Down votes
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only for Questions
    GROUP BY 
        p.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  -- Only Gold badges
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 3  -- Get top 3 posts per user
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    GoldBadgeCount,
    CASE 
        WHEN GoldBadgeCount > 0 THEN 'Gold Badge Holder'
        ELSE 'No Gold Badge'
    END AS BadgeStatus
FROM 
    TopPosts
ORDER BY 
    GoldBadgeCount DESC, 
    UpVoteCount DESC;
