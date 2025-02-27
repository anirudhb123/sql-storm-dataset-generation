WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 /* Questions only */
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes, /* Upvotes minus Downvotes */
        COUNT(CASE WHEN b.Id IS NOT NULL THEN 1 END) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 /* Questions */
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(ph.CloseReasonType, 'Open') AS PostStatus,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 /* Questions only */
    GROUP BY 
        p.Id, ph.CloseReasonType
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.NetVotes,
    ua.BadgeCount,
    qs.PostId,
    qs.Title AS QuestionTitle,
    qs.Score AS QuestionScore,
    qs.ViewCount AS QuestionViews,
    qs.CreationDate AS QuestionDate,
    qs.CommentCount AS QuestionComments,
    qs.PostStatus,
    rp.Rank AS UserRankWithinQuestions
FROM 
    UserActivity ua
LEFT JOIN 
    QuestionSummary qs ON ua.UserId = qs.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON qs.PostId = rp.PostId AND rp.Rank <= 3 /* Top 3 questions per user */
WHERE 
    ua.NetVotes > 0
ORDER BY 
    ua.NetVotes DESC, qs.PostId DESC
LIMIT 10;
