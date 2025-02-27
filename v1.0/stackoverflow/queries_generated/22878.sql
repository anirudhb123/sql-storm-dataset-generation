WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedScore,
        CASE 
            WHEN p.Tags LIKE '%sql%' THEN 'SQL related'
            WHEN p.Tags LIKE '%performance%' THEN 'Performance related'
            ELSE 'General'
        END AS Category
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AcceptedScore,
        rp.Category,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AcceptedScore, rp.Category
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (PARTITION BY pd.Category ORDER BY pd.ViewCount DESC, pd.AcceptedScore DESC) AS RankWithinCategory
    FROM 
        PostDetails pd
    WHERE 
        pd.CommentCount > 0
),
FilteredRanks AS (
    SELECT 
        *,
        CASE 
            WHEN RankWithinCategory <= 5 THEN 'Top 5'
            ELSE 'Others'
        END AS RankCategory
    FROM 
        RankedPosts
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.AcceptedScore,
    fr.CommentCount,
    fr.BadgeCount,
    fr.RankCategory,
    COALESCE(FormatMessage, 'No comments') AS CommentStatus,
    CASE 
        WHEN fr.AcceptedScore IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    FilteredRanks fr
LEFT JOIN (
    SELECT 
        PostId,
        STRING_AGG(Text, '; ') AS FormatMessage
    FROM 
        Comments
    GROUP BY 
        PostId
) cm ON cm.PostId = fr.PostId
ORDER BY 
    fr.RankCategory, fr.ViewCount DESC
LIMIT 50;

