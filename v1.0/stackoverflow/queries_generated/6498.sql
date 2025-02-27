WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ts.TagName,
    ts.PostCount,
    ts.AvgScore,
    phs.EditCount,
    phs.LastEditDate
FROM 
    UserActivity ua
JOIN 
    TagStats ts ON ua.TotalPosts > 0
JOIN 
    PostHistoryStats phs ON phs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
ORDER BY 
    ua.TotalPosts DESC, ua.TotalUpVotes DESC;
