WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),

PostScoreStats AS (
    SELECT 
        PostId,
        AVG(Score) OVER () AS AvgScore,
        MAX(Score) OVER () AS MaxScore,
        MIN(Score) OVER () AS MinScore
    FROM 
        Posts
),

UserParticipation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),

ClosedPosts AS (
    SELECT 
        h.PostId,
        h.UserId,
        h.Comment,
        ph.Name AS CloseReason
    FROM 
        PostHistory h
    JOIN 
        PostHistoryTypes ph ON h.PostHistoryTypeId = ph.Id
    WHERE 
        h.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
),

FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        ps.AvgScore,
        ps.MaxScore,
        ps.MinScore,
        up.UserId,
        up.DisplayName AS UserDisplayName,
        up.PostsCount,
        up.CommentsCount,
        cp.CloseReason
    FROM 
        RecentPosts rp
    JOIN 
        PostScoreStats ps ON rp.PostId = ps.PostId
    LEFT JOIN 
        UserParticipation up ON rp.PostId = up.UserId 
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.RecentRank <= 10
        AND (rp.CommentCount > 0 OR cp.CloseReason IS NOT NULL)
)

SELECT 
    *,
    CASE 
        WHEN UserDisplayName IS NULL THEN 'No Activity'
        ELSE UserDisplayName
    END AS ParticipationStatus,
    CASE 
        WHEN CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CONCAT('Post ', PostId, ': ', Title, ' | Score: ', COALESCE(MaxScore, 0), 
           ' | Avg: ', COALESCE(AvgScore, 0), ' | Min: ', COALESCE(MinScore, 0)) AS PostSummary
FROM 
    FinalOutput
ORDER BY 
    CreationDate DESC;
