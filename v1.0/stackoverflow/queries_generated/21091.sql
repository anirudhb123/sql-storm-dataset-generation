WITH RankedPosts AS (
    SELECT 
        p.Id AS post_id,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rank_score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS recent_post_rank,
        COALESCE(COUNT(c.Id), 0) AS comment_count 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE()) 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score, p.ViewCount, p.AcceptedAnswerId
),
UserEngagement AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes,
        COUNT(b.Id) AS badge_count,
        COUNT(DISTINCT ph.PostId) AS post_edit_count 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        rp.post_id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ue.user_id,
        ue.DisplayName,
        ue.upvotes,
        ue.downvotes,
        ue.badge_count,
        ue.post_edit_count,
        MAX(ue.badge_count) OVER () AS max_badges,
        MIN(rp.rank_score) OVER () AS lowest_rank_score
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserEngagement ue ON rp.AcceptedAnswerId = ue.user_id
)
SELECT 
    ps.post_id,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.DisplayName AS user_display_name,
    ps.upvotes,
    ps.downvotes,
    ps.badge_count,
    CASE 
        WHEN ps.badge_count IS NULL THEN 'No badges'
        WHEN ps.badge_count > MAX(ps.max_badges) OVER () THEN 'Elite User'
        ELSE 'Regular User'
    END AS user_status,
    ps.lowest_rank_score,
    CASE 
        WHEN ps.rank_score = 1 THEN 'Top Scorer'
        WHEN ps.rank_score BETWEEN 2 AND 5 THEN 'High Scorer'
        ELSE 'Needs Improvement'
    END AS scoring_status
FROM 
    PostSummary ps
WHERE 
    ps.Score > (SELECT AVG(Score) FROM Posts) 
    AND ps.CreationDate IS NOT NULL
ORDER BY 
    ps.Score DESC, 
    ps.post_id; 
