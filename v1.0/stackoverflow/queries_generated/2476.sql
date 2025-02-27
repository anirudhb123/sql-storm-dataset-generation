WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        SUM(v.VoteTypeId = 3) AS TotalDownvotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalUpvotes,
    ups.TotalDownvotes,
    CASE 
        WHEN ups.TotalPosts > 100 THEN 'Veteran'
        WHEN ups.TotalPosts BETWEEN 50 AND 100 THEN 'Experienced'
        ELSE 'Novice' 
    END AS ExperienceLevel,
    json_agg(rph.UserDisplayName) FILTER (WHERE rph.RecentHistory = 1) AS RecentEditors
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPostHistory rph ON ups.UserId = rph.UserId
WHERE 
    ups.PostRank <= 10
GROUP BY 
    ups.UserId, ups.DisplayName, ups.TotalPosts, ups.QuestionCount, ups.AnswerCount, ups.TotalUpvotes, ups.TotalDownvotes
ORDER BY 
    ups.TotalPosts DESC;
