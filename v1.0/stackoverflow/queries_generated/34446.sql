WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        AVG(v.vote_Type) OVER (PARTITION BY p.Id) AS AvgVoteType -- Assuming a simple mapping for vote types
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    AND 
        p.Score > 0 -- Only posts with a positive score
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.AvgVoteType
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per type
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.Title,
    fp.Score,
    fp.ViewCount,
    ue.DisplayName,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges,
    ue.PostsCount,
    ue.TotalViews,
    CASE 
        WHEN fp.CommentCount = 0 THEN 'No comments'
        ELSE CONCAT(fp.CommentCount, ' comments')
    END AS CommentsInfo,
    CASE 
        WHEN ue.PostsCount > 0 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserStatus
FROM 
    FilteredPosts fp
JOIN 
    UserEngagement ue ON fp.PostId = ue.UserId
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
