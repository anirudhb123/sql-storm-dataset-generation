WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ah.Id) AS AnswerCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ah ON p.Id = ah.ParentId AND ah.PostTypeId = 2
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
BadgeStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MIN(ph.CreationDate) AS InitialCreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering only Closed and Reopened histories
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.AnswerCount,
    bs.BadgeCount,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    ph.ClosedDate,
    ph.InitialCreationDate,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL AND ph.InitialCreationDate < ph.ClosedDate THEN
            'Closed'
        ELSE 
            'Active' 
    END AS Status,
    CASE 
        WHEN rp.UpVotes - rp.DownVotes > 0 THEN 'Popular'
        WHEN rp.DownVotes - rp.UpVotes > 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS Popularity,
    CONCAT('Post Title: ', rp.Title, ' | Created by User ID: ', rp.PostId) AS PostInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgeStatistics bs ON rp.OwnerUserId = bs.UserId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 ranked posts per user
ORDER BY 
    rp.CreationDate DESC
OFFSET 
    CASE WHEN ? IS NULL THEN 0 ELSE ? END ROWS 
FETCH NEXT 
    CASE WHEN ? IS NULL THEN 10 ELSE ? END ROWS ONLY; 
