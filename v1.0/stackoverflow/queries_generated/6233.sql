WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT ph.Id) AS TotalHistoryEntries
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalBadges,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.LastPostDate,
        pa.PostId,
        pa.Title,
        pa.TotalComments,
        pa.LastEditDate,
        pa.TotalHistoryEntries
    FROM 
        UserStats us
    JOIN 
        PostActivity pa ON us.UserId = pa.OwnerUserId
    WHERE 
        us.TotalPosts > 0
)
SELECT 
    au.DisplayName,
    au.TotalUpVotes,
    au.TotalDownVotes,
    au.TotalBadges,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    pa.Title,
    pa.TotalComments,
    pa.LastEditDate,
    pa.TotalHistoryEntries
FROM 
    ActiveUsers au
JOIN 
    PostActivity pa ON au.PostId = pa.PostId
ORDER BY 
    au.TotalUpVotes DESC, au.TotalDownVotes ASC, au.LastPostDate DESC;
