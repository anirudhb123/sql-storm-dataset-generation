WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerName,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostWithCommentStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActivity,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        PostsTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.AnswerCount
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        pwcs.PostId,
        pwcs.Title,
        pwcs.ViewCount,
        pwcs.AnswerCount,
        pwcs.CommentCount,
        cp.CloseVoteCount,
        cp.FirstCloseDate,
        CASE 
            WHEN cp.CloseVoteCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        PostWithCommentStats pwcs
    LEFT JOIN 
        ClosedPostHistory cp ON pwcs.PostId = cp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.AnswerCount,
    fr.CommentCount,
    COALESCE(fr.CloseVoteCount, 0) AS CloseVoteCount,
    fr.FirstCloseDate,
    fr.PostStatus,
    CASE 
        WHEN fr.CloseVoteCount IS NULL THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus,
    CASE 
        WHEN fr.PostStatus = 'Closed' AND fr.CommentCount = 0 THEN 'Need Attention'
        ELSE 'Monitor'
    END AS Recommendation
FROM 
    FinalReport fr
WHERE 
    (fr.ViewCount > 100 OR fr.AnswerCount > 5)
ORDER BY 
    fr.ViewCount DESC,
    fr.AnswerCount DESC;
