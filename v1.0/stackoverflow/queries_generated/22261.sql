WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        LEAST(DATE_PART('year', AGE(u.CreationDate)), 10) AS YearsActive
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularQuestions AS (
    SELECT 
        Id, 
        Title, 
        ViewCount, 
        AnswerCount,
        DENSE_RANK() OVER (ORDER BY ViewCount DESC) AS RankByViews
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        COUNT(*) AS CloseActions,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        p.Id, ph.UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- Bounty Start
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pq.Title AS PopularQuestionTitle,
    pq.ViewCount AS PopularQuestionViews,
    PhC.CloseActions AS CloseActionCount,
    CASE 
        WHEN PhC.CloseActions IS NULL THEN 'No Closure Actions' 
        ELSE PhC.CloseReasons 
    END AS CloseReasons,
    pm.CommentCount,
    pm.AvgBounty
FROM 
    UserStats us
JOIN 
    PopularQuestions pq ON us.QuestionCount > 0
LEFT JOIN 
    ClosedPosts PhC ON us.UserId = PhC.UserId
LEFT JOIN 
    PostMetrics pm ON pm.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = us.UserId)
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, pq.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
