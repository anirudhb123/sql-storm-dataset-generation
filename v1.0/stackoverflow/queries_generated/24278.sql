WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankDate
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
HighestScoring AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        RankScore = 1
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        hp.PostId,
        hp.Title,
        COALESCE(ue.UserId, -1) AS CreatorUserId,
        COALESCE(ue.DisplayName, 'Unknown User') AS CreatorDisplayName,
        hp.Score AS PostScore,
        hp.ViewCount,
        COALESCE(ue.CommentCount, 0) AS UserCommentCount,
        ue.UpvoteCount,
        ue.DownvoteCount,
        (SELECT COUNT(DISTINCT LinkTypeId) FROM PostLinks pl WHERE pl.PostId = hp.PostId) AS UniqueLinkCount
    FROM 
        HighestScoring hp
    LEFT JOIN 
        UserEngagement ue ON hp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ue.UserId AND p.PostTypeId = 1)
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreatorDisplayName,
        SUM(ps.PostScore + ps.UserCommentCount + ps.UpvoteCount - ps.DownvoteCount + ps.UniqueLinkCount) AS TotalEngagement,
        MAX(DATE_PART('day', NOW() - p.CreationDate)) AS PostAgeInDays
    FROM 
        PostSummary ps
    JOIN 
        Posts p ON ps.PostId = p.Id
    GROUP BY 
        ps.PostId, ps.Title, ps.CreatorDisplayName
    HAVING 
        TotalEngagement > 10 AND PostAgeInDays < 30
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.CreatorDisplayName,
    fs.TotalEngagement,
    CASE 
        WHEN fs.TotalEngagement > 50 THEN 'Hot'
        WHEN fs.TotalEngagement BETWEEN 20 AND 50 THEN 'Trending'
        ELSE 'Normal'
    END AS EngagementLevel
FROM 
    FinalStats fs
ORDER BY 
    fs.TotalEngagement DESC
LIMIT 10;
