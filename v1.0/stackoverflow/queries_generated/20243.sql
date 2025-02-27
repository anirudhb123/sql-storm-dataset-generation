WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(EXTRACT(EPOCH FROM (NOW() - p.CreationDate))/3600) AS AvgHoursToFirstAnswer
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS ClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.AvgHoursToFirstAnswer, 0) AS AvgHoursToFirstAnswer,
        COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
        COALESCE(cl.ClosedDate, NULL) AS FirstClosedPostDate,
        CASE
            WHEN cl.ClosedDate IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS HasClosedPost
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        VoteSummary vs ON EXISTS (
            SELECT 1 
            FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Id = vs.PostId
        )
    LEFT JOIN 
        ClosedPosts cl ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Posts.Id = cl.PostId)
    WHERE 
        u.Reputation > 0  -- Only consider users with positive reputation
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.TotalBadges,
    fs.TotalPosts,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.AvgHoursToFirstAnswer,
    fs.TotalUpVotes,
    fs.TotalDownVotes,
    fs.FirstClosedPostDate,
    fs.HasClosedPost
FROM 
    FinalStats fs
ORDER BY 
    fs.TotalPosts DESC, fs.QuestionCount DESC
LIMIT 100;

-- Execute this statement to retrieve the top 100 users based on their post activity,
-- badge achievements, and whether they have had posts closed, presenting a comprehensive
-- overview of their contributions within the Stack Exchange community.
