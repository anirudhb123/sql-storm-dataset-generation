WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
        AND p.Score IS NOT NULL
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
        AND b.Date >= (CURRENT_DATE - INTERVAL '2 years')
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment END, '; ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '3 months')
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.PostId,
    ue.DisplayName AS UserName,
    ue.UpVotes,
    ue.DownVotes,
    ue.CommentCount,
    COALESCE(pb.BadgeCount, 0) AS BadgeCount,
    pha.HistoryCount,
    pha.Comments,
    CASE 
        WHEN p.Score >= 10 THEN 'Popular Post'
        WHEN p.ViewCount < 100 THEN 'Low Engagement'
        ELSE 'Regular Post'
    END AS EngagementLevel,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    RankedPosts p
JOIN 
    UserEngagement ue ON p.OwnerUserId = ue.UserId
LEFT JOIN 
    FilteredBadges pb ON ue.UserId = pb.UserId
LEFT JOIN 
    PostHistoryAggregates pha ON p.PostId = pha.PostId
WHERE 
    p.PostRank = 1
ORDER BY 
    p.ViewCount DESC NULLS LAST,
    ue.UpVotes DESC,
    pha.HistoryCount DESC;
