WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        MAX(CASE WHEN bh.PostHistoryTypeId = 10 THEN CloseReasonId END) AS CloseReasonId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId AND bh.PostHistoryTypeId IN (10, 11, 12)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.Score
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostStatistics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        ub.BadgeCount,
        ub.BadgeNames,
        COALESCE(rp.CloseReasonId, 'Open') AS PostStatus,
        CASE 
            WHEN rp.Score >= 0 THEN 'Non-negative' 
            ELSE 'Negative' END AS ScoreLabel,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Active Discussion'
            WHEN rp.CommentCount IS NULL THEN 'No comments yet'
            ELSE 'Comments disabled'
        END AS CommentStatus,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CreationDate DESC) AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    ps.Id AS PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerUserId,
    ps.Score,
    ps.BadgeCount,
    ps.BadgeNames,
    ps.PostStatus,
    ps.ScoreLabel,
    ps.CommentStatus,
    ps.OverallRank
FROM 
    PostStatistics ps
WHERE 
    ps.CommentStatus = 'Active Discussion'
ORDER BY 
    ps.OverallRank, ps.CreationDate DESC
LIMIT 100;

-- Additional queries can be included to produce flip-side insights for inactive posts.

This query incorporates various advanced SQL constructs such as Common Table Expressions (CTEs), window functions, outer joins, and conditional aggregations while maintaining an intricate relationship with the tables defined. It analyzes posts to provide an overview of user interactions including badges, scores, statuses, and ranks, while also filtering for posts with active discussions.
